class RoundRobin < Group
  def rounds
    #boards.pluck(:round).max || 0
    if tournaments_players.count > 0
      tournaments_players.count.odd? ? tournaments_players.count : tournaments_players.count - 1
    else
      0
    end
  end

  def completed?
    self.completed_round == self.boards.maximum(:round)
  end

  def sufficient_players?
    self.tournaments_players.count > 2
  end

  def delete_round round
    ActiveRecord::Base.transaction do
      if round == 1
        # reset everything if round 1
        self.boards.delete_all
      else
        # delete results only
        self.boards.where(round: round).update_all(result: nil, walkover: false)
      end
      #Standing.joins(:tournaments_player).where(round: round, tournaments_players: { group: self }).delete_all
      Standing.joins(:tournaments_player).where(tournaments_players: { group: self }).where("round >= ?", round - 1).delete_all
    end
  end

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
        Board.create!(tournament: self.tournament, group: self, number: idx, round: round, white: w_player, black: b_player)
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

      result = player_result_on_round(self, t_player, round, false)
      prev_wins = prev_standing ? prev_standing.wins : 0
      total_wins = prev_wins + (result == 1 ? 1 : 0)

      standing.update!(tournament: self.tournament, points: t_player.points, 
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
          m += self.draw_point * opponent.points if opponent
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
      snapshoot_points(round)
      compute_tiebreaks(round)

      # final round
      if round == last_round
        # update ratings for rated tournament
        update_ratings if self.tournament.rated

        # update total games played by each player
        update_total_games

        # update h2h ranks for tied top three players
        update_h2h(round)
      end
    end
    true
  end

  def sorted_standings round
    query = self.tournament.standings.joins(tournaments_player: :player).
      where('tournaments_players.group_id': self.id, round: round).
      order(blacklisted: :asc, points: :desc)
    query = query.order('h2h_points DESC NULLS LAST') if self.h2h_tb
    query.order(sb: :desc, wins: :desc,
            playing_black: :desc, 'tournaments_players.start_rating': :desc, 'players.name': :asc)
  end

  def sorted_merged_standings
    return [] unless merged_standings_config

    merged_standings_config.merged_standings.joins(:player).
      order('points DESC, ' + self.h2h_tb ? ' h2h_points DESC NULLS LAST, ' : '' + 
            'sb DESC, wins DESC, playing_black DESC, players.name ASC')
  end

  private
  def player_result group, player1, player2
    # returns points for player1 against player2
    board_played = group.boards.where(white: player1, black: player2).first ||
                   group.boards.where(black: player1, white: player2).first
    return 0 if board_played.nil? # no game played
    case board_played.result
    when 'white'
      return group.win_point if board_played.white == player1
      return 0 if board_played.black == player1
    when 'black'
      return 0 if board_played.white == player1
      return group.win_point if board_played.black == player1
    when 'draw'
      return group.draw_point
    else
      return 0 # no result
    end
  end

  def player_result_on_round group, player1, round, include_walkover
    board_played =  group.boards.where(round: round, white: player1).first ||
                    group.boards.where(round: round, black: player1).first
    return 0 if board_played.nil? # no game played
    return 0 if board_played.walkover and not include_walkover # no result if walkover is not included

    case board_played.result
    when 'white'
      return group.win_point if board_played.white == player1
      return 0 if board_played.black == player1
    when 'black'
      return 0 if board_played.white == player1
      return group.win_point if board_played.black == player1
    when 'draw'
      return group.draw_point
    else
      return 0 # no result
    end
  end

public
  def update_h2h round
    super
  end
end
