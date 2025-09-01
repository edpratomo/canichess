class RoundRobin < Group

  def current_round
    last_board = boards.where(group: self, result: nil).order(:round).first || self.boards.order(:round).last
    return 0 unless last_board
    if last_board.round > 1
      # check standings
      prev_round_standings = self.tournaments_players.joins(:standings).where('standings.round': last_board.round - 1).count
      if prev_round_standings > 0
        return last_board.round
      else
        return last_board.round - 1
      end
    else
      return last_board.round
    end
  end

  def reorder_boards round
    
  end

  def start
    self.reload
    return if self.tournaments_players.count < 3
    return if self.current_round > 0 # already started

    self.tournaments_players.each do |t_player|
      t_player.update!(start_rating: t_player.rating)
    end

    berger = RR_Tournament.new(self.tournaments_players.count)
    
    # create maps for players: int -> TournamentsPlayer
    players_map = self.tournaments_players.each_with_index.inject({}) do |m,o|
      m[o[1] + 1] = o[0] # start with 1
      m  
    end

    berger.generate_pairings
    idx = 0
    prev_round = 0
    berger.get_pairings do |round, white, black|
      if round != prev_round
        prev_round = round
        idx = 0
      end
      w_player = players_map[white.to_i]
      b_player = players_map[black.to_i]
      
      # create board for this pairing, skip BYE
      if w_player and b_player
        idx += 1
        Board.create!(tournament: self, group: self, number: idx, round: round, white: w_player, black: b_player)
      end
      self.reorder_boards(round)
    end
  end

  def snapshoot_points round
    return if current_round < 1
    self.reload
    self.tournaments_players.each do |t_player|
      standing = Standing.find_or_create_by(tournaments_player: t_player, round: round)
      if round > 1
        prev_standing = Standing.find_by(tournaments_player: t_player, round: round - 1)
      end
      prev_playing_black = prev_standing ? prev_standing.playing_black : 0
      total_playing_black = prev_playing_black + t_player.playing_black(round)

      result = player_result_on_round(group, t_player, round, false)
      prev_wins = prev_standing ? prev_standing.wins : 0
      total_wins = prev_wins + (result == 1 ? 1 : 0)

      standing.update!(tournament: self, points: t_player.points, 
                       playing_black: total_playing_black, 
                       wins: total_wins, blacklisted: t_player.blacklisted)
    end
  end

  def compute_tiebreaks round
    t_players = self.tournaments_players.joins(:standings).where('standings.round': round).order('standings.points': :desc)

    # sonneborn-Berger
    t_players.each do |t_player|
      tb_sb = t_player.games.inject(0) do |m, game|
        if game.result == 'white' and game.white == t_player
          m += game.black.points if game.black
        elsif game.result == 'black' and game.black == t_player
          m += game.white.points if game.white
        elsif game.result == 'draw'
          opponent = [game.white, game.black].reject {|e| e == t_player }.first
          m += 0.5 * opponent.points if opponent
        end
        m
      end

      standing = t_player.standings.find_by(round: round)
      standing.update!(sb: tb_sb)
    end
  end

  def finalize_round round
    last_round = self.boards.last.round

    unless self.boards.where(round: round).where(result: nil).empty?
      errors.add(:completed_round, "All boards in group #{self.name} must have finished first")
      return false
    end

    transaction do
      if current_round > 0
        update!(completed_round: completed_round + 1)
      end

      snapshoot_points(round)
      compute_tiebreaks(round)

      # final round
      if round == last_round
        # update ratings for rated tournament
        update_ratings() if self.tournament.rated

        # update total games played by each player
        update_total_games()

        # update h2h ranks for tied top three players
        update_h2h(round)
      end
    end
    true
  end

  def sorted_standings round
    self.tournament.standings.joins(tournaments_player: :player).
      where('tournaments_players.group_id': self.id, round: round).
      order(blacklisted: :asc, points: :desc, sb: :desc, h2h_rank: :asc, wins: :desc,
            playing_black: :desc, 'tournaments_players.start_rating': :desc, 'players.name': :asc)
  end

  private
  def update_h2h round
    final_stds = standings.joins(tournaments_player: :player).
                  where('tournaments_players.group_id': self.id, round: round).
                  order(blacklisted: :asc, points: :desc, sb: :desc)

    curr_idx = 0

    (0..2).each do |i|
      next if i < curr_idx

      # find players with same points
      tied_players_idx = ((i+1)..final_stds.size - 1).select do |j|
        final_stds[j].points == final_stds[i].points and final_stds[j].sb == final_stds[i].sb
      end

      if tied_players_idx.empty?
        curr_idx = i + 1
        next
      end

      if tied_players_idx.size == 1
        opponent_idx = tied_players_idx.first
        opponent = final_stds[opponent_idx].tournaments_player

        Rails.logger.debug("Tied players: <#{final_stds[i].tournaments_player.player.name}> and <#{final_stds[opponent_idx].tournaments_player.player.name}>")
        Rails.logger.debug("Tied players: <#{final_stds[i].tournaments_player.id}> and <#{final_stds[opponent_idx].tournaments_player.id}>")

        board_played = self.boards.where(white: final_stds[i].tournaments_player, black: opponent).first
        is_swap = if board_played
          if board_played.result == 'white'
            false
          elsif board_played.result == 'black'
            true
          else
            nil
          end
        else 
          Rails.logger.debug("not found")
          board_played = self.boards.where(black: final_stds[i].tournaments_player, white: opponent).first
          if board_played
            Rails.logger.debug("board_played: #{board_played.id} for players #{final_stds[i].tournaments_player.player.name} and #{opponent.player.name}")
            if board_played.result == 'black'
              false
            elsif board_played.result == 'white'
              true
            else
              nil
            end
          else
            Rails.logger.debug("not found again")
            nil
          end
        end

        unless is_swap.nil? # resolved
          if is_swap
            transaction do
              final_stds[i].update(h2h_rank: opponent_idx)
              final_stds[opponent_idx].update(h2h_rank: i)
            end
            curr_idx = opponent_idx + 1
            next 
          else
            transaction do
              final_stds[i].update(h2h_rank: i)
              final_stds[opponent_idx].update(h2h_rank: opponent_idx)
            end
            curr_idx = opponent_idx + 1
            next
          end
        else # still tied
          transaction do
            final_stds[i].update(h2h_rank: i)
            final_stds[opponent_idx].update(h2h_rank: i)
          end
          curr_idx = opponent_idx + 1
          next
        end

      else
  
        Rails.logger.debug("Tied players: #{tied_players_idx.inspect} for player #{final_stds[i].tournaments_player.player.name}")
        pp [i, tied_players_idx].flatten.map {|e| final_stds[e].tournaments_player.name}

        players_points = {}
        group = final_stds[i].tournaments_player.group
        # multiple players tied, find head-to-head results
        [i, tied_players_idx].flatten.each do |j|
          [i, tied_players_idx].flatten.each do |k|
            next if j == k
            players_points[j] ||= 0
            players_points[j] += player_result(group, final_stds[j].tournaments_player, final_stds[k].tournaments_player)
          end
        end

        # update h2h_rank for all tied players
        points_groups = players_points.inject({}) do |m,o|
          player_idx, points = o
          m[points] ||= []
          m[points] << player_idx
          m
        end

        Rails.logger.debug("Points groups: #{points_groups.inspect}")
        pp points_groups

        points_groups.keys.sort.reverse.each_with_index do |points,idx|
          points_groups[points].each do |player_idx|
            final_stds[player_idx].update(h2h_rank: i + idx)
          end
        end

        curr_idx = tied_players_idx.last + 1
        next
      end
    end
  end

end
