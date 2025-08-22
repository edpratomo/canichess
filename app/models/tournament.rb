class Tournament < ApplicationRecord
  include Eventable

  # polymorphic many-to-many:
  # tournaments <= events_sponsors => sponsors
  # simuls      <= events_sponsors => sponsors
  has_many :events_sponsors, :as => :eventable
  has_many :sponsors, :through => :events_sponsors, :as => :eventable

  has_many :boards
  has_many :standings

  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players

  # for RR tournaments
  has_many :groups

  validate :all_boards_finished, on: :update, if: :completed_round_changed?
  validates :rounds, presence: true, unless: :is_round_robin?

  after_create :create_past_event
  before_destroy :delete_past_event

  def is_round_robin?
    system == 'round_robin'
  end

  def get_results round=nil
    round ||= current_round
    boards.where(round: round).where.not(result: nil).map {|e|
      {id: e.id, result: e.result, walkover: e.walkover}
    }
  end

  def boards_per_round
    (players.size.to_f / 2).ceil
  end

  def percentage_completion
    return 100 if completed_round == rounds
    return 0 if current_round == 0
    n_boards_per_round = boards_per_round
    total_boards = n_boards_per_round * rounds
    boards_finished_current_round = boards.where(round: current_round).where.not(result: nil).size
    (((n_boards_per_round * completed_round + boards_finished_current_round) * 100) / (n_boards_per_round * rounds)).floor 
  end

  def delete_group_boards group
    boards.where(group: group).destroy_all
  end

  def start_rr_group group
    group.reload
    return if group.tournaments_players.count < 3
    return if group.current_round > 0 # already started

    group.tournaments_players.each do |t_player|
      t_player.update!(start_rating: t_player.rating)
    end

    berger = RR_Tournament.new(group.tournaments_players.count)
    
    # create maps for players: int -> TournamentsPlayer
    players_map = group.tournaments_players.each_with_index.inject({}) do |m,o|
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
        Board.create!(tournament: self, group: group, number: idx, round: round, white: w_player, black: b_player)
      end
      reorder_boards(group, round)
    end
  end

  def start_rr
    self.update(max_walkover: 100)
    groups.each do |group|
      start_rr_group(group)
    end
  end

  def reorder_boards group, round # for RR tournaments
    
  end

  def add_player args
    new_player = if args[:id] # existing player
      Player.find(args[:id])
    elsif args[:name]
      Player.create!(name: args[:name])
    end
    players << new_player
    if args[:group]
      new_player.tournaments_players.find_by(tournament: self).update!(group: args[:group])
    end
    new_player
  end

  def player_result group, player1, player2
    # returns points for player1 against player2
    board_played = group.boards.where(white: player1, black: player2).first ||
                   group.boards.where(black: player1, white: player2).first
    return 0 if board_played.nil? # no game played
    case board_played.result
    when 'white'
      return 1 if board_played.white == player1
      return 0 if board_played.black == player1
    when 'black'
      return 0 if board_played.white == player1
      return 1 if board_played.black == player1
    when 'draw'
      return 0.5
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
      return 1 if board_played.white == player1
      return 0 if board_played.black == player1
    when 'black'
      return 0 if board_played.white == player1
      return 1 if board_played.black == player1
    when 'draw'
      return 0.5
    else
      return 0 # no result
    end
  end

  def update_h2h group, round
    final_stds = standings.joins(tournaments_player: :player).
                  where('tournaments_players.group_id': group.id, round: round).
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

        board_played = group.boards.where(white: final_stds[i].tournaments_player, black: opponent).first
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
          board_played = group.boards.where(black: final_stds[i].tournaments_player, white: opponent).first
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

  def sorted_standings_rr group, round
    standings.joins(tournaments_player: :player).where('tournaments_players.group_id': group.id, round: round).
          order(blacklisted: :asc, points: :desc, sb: :desc, h2h_rank: :asc, wins: :desc,
                playing_black: :desc, 'tournaments_players.start_rating': :desc, 'players.name': :asc)
  end

  def sorted_standings round=nil
    round ||= completed_round
    # 13.1.3.1 Joining Nested Associations (Single Level)
    standings.joins(tournaments_player: :player).where(round: round).
              order(blacklisted: :asc, points: :desc, median: :desc, solkoff: :desc, cumulative: :desc, 
                    playing_black: :desc, 'tournaments_players.start_rating': :desc, 'players.name': :asc)
  end

  def compute_tiebreaks round=nil
    round ||= completed_round
    t_players = tournaments_players.joins(:standings).where('standings.round': round).order('standings.points': :desc)

    # first pass: cumulative
    t_players.each do |t_player|
      standing = t_player.standings.find_by(round: round)
      # cumulative
      tb_cumulative = t_player.standings.where(round: (1..round).to_a).map(&:points).sum
      standing.update!(cumulative: tb_cumulative)
    end

    t_players.each do |t_player|
      standing = t_player.standings.find_by(round: round)
      opponents_points = t_player.prev_opps.reject(&:nil?).map do |opponent|
        Standing.find_by(tournaments_player: opponent, round: round).points
      end.sort

      # solkoff
      tb_solkoff = opponents_points.sum

      # modified median
      t_player_points = standing.points
      tb_modified_median = if t_player_points == rounds / 2
        opponents_points.shift
        opponents_points.pop
        opponents_points.sum
      elsif t_player_points > rounds / 2
        opponents_points.shift
        opponents_points.sum
      else
        opponents_points.pop
        opponents_points.sum
      end
      
      # opposition cumulative
      tb_opposition_cumulative = t_player.prev_opps.reject(&:nil?).map do |opponent|
        Standing.find_by(tournaments_player: opponent, round: round).cumulative
      end.sum

      Rails.logger.info("standing id: #{standing.id}")
      Rails.logger.info("opposition_cumulative: #{tb_opposition_cumulative}")
      Rails.logger.info("solkoff: #{tb_solkoff}")
      Rails.logger.info("modified median: #{tb_modified_median}")

      # update standing for t_player
      standing.update!(median: tb_modified_median, solkoff: tb_solkoff, opposition_cumulative: tb_opposition_cumulative)
    end
  end

  def finalize_round_rr group, round
    last_round = group.boards.last.round

    unless group.boards.where(round: round).where(result: nil).empty?
      errors.add(:completed_round, "All boards in group #{group.name} must have finished first")
      return false
    end

    transaction do
      snapshoot_points_rr(group, round)
      compute_tiebreaks_rr(group, round)

      # final round
      if round == last_round
        # update ratings for rated tournament
        update_ratings(group) if self.rated

        # update total games played by each player
        update_total_games(group)

        # update h2h ranks for tied top three players
        update_h2h(group, round)
      end
    end
    true
  end

  def compute_tiebreaks_rr group, round
    t_players = group.tournaments_players.joins(:standings).where('standings.round': round).order('standings.points': :desc)

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

  def finalize_round
    return if completed_round == rounds # tournament is finished already

    transaction do
      # remove players who lost by WO more than max_walkover
      withdraw_wo_players

      # check if no pairing has been created yet
      if current_round > 0
        update!(completed_round: completed_round + 1)
        snapshoot_points
      else
        # first round, save start_rating for each tournament player
        tournaments_players.each do |t_player|
          t_player.update!(start_rating: t_player.rating)
        end
      end
      if completed_round < rounds
        generate_pairings
      else
        # final round
        compute_tiebreaks

        # update ratings for rated tournament
        update_ratings if self.rated

        # update total games played by each player
        update_total_games
      end
    end
    true
  end

  def withdraw_wo_players
    tournaments_players.where('wo_count > ?', self.max_walkover).each do |t_player|
      t_player.update!(blacklisted: true)
    end
  end

  def update_total_games group=nil
    group_tournaments_players = if group
      group.tournaments_players
    else
      tournaments_players
    end

    group_tournaments_players.each do |t_player|
      games_played = t_player.games.reject {|e| e.contains_bye? }.size
      t_player.player.update!(games_played: t_player.games_played + games_played)
      if self.rated
        t_player.player.update!(rated_games_played: t_player.rated_games_played + games_played)
      end
    end
  end

  def update_ratings group=nil
    group_tournaments_players = if group
      group.tournaments_players
    else
      tournaments_players
    end

    group_boards = if group
      boards.where(group: group)
    else
      boards
    end

    result_to_rank = {
      'white' => [1, 2],
      'black' => [2, 1],
      'draw'  => [1, 1]
    }

    # mapping AR instances to MyPlayer instances
    ar_my_players = group_tournaments_players.inject({}) do |m,o|
      m[o.id] = MyPlayer.new(o)
      m
    end

    games = group_boards.reject {|e| e.contains_bye? or e.result == 'noshow' or e.result.nil? or e.walkover}

    period = Glicko2::RatingPeriod.from_objs(ar_my_players.values)

    transaction do
      games.each do |game|
        period.game([ar_my_players[game.white.id], ar_my_players[game.black.id]], result_to_rank[game.result])
      end
      # tau constant = 0.5
      period.generate_next(0.5).players.each(&:update_obj)

      ar_my_players.values.each(&:save_rating)

      # update end_rating for each tournament_player
      group_tournaments_players.each do |t_player|
        t_player.update!(end_rating: t_player.rating)
      end
    end
  end

  def current_round_rr group
    last_board = boards.where(group: group, result: nil).order(:round).first || group.boards.order(:round).last
    return 0 unless last_board
    if last_board.round > 1
      # check standings
      prev_round_standings = group.tournaments_players.joins(:standings).where('standings.round': last_board.round - 1).count
      if prev_round_standings > 0
        return last_board.round
      else
        return last_board.round - 1
      end
    else
      return last_board.round
    end
  end

  def current_round group=nil
    return current_round_rr(group) if group
    last_board = boards.order(:round).last
    last_board ? last_board.round : 0
  end

  def next_round group=nil
    current_round(group) + 1
  end

  # must add validation that previous round must be completed
  def generate_pairings
    players_list = ActiveRecordPlayersList.new(self)
    pairing = Pairing.new(players_list)
    round = next_round
    # use bipartite for this round?
    use_bipartite_matching = bipartite_matching.any?(round)
    if use_bipartite_matching
      Rails.logger.debug("Using bipartite matching for round #{round}")
    else
      Rails.logger.debug("Using general matching for round #{round}")
    end
    pairing.generate_pairings(use_bipartite_matching) {|idx, w_player, b_player|
      Board.create!(tournament: self, number: idx, round: round, white: w_player, black: b_player)
    }
  end

  def snapshoot_points_rr group, round
    return if current_round < 1
    group.reload
    group.tournaments_players.each do |t_player|
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

  # create snapshots of every player for a specific round
  def snapshoot_points
    return if current_round < 1
    tournaments_players.each do |t_player|
      standing = Standing.find_or_create_by(tournaments_player: t_player, round: current_round)
      standing.update!(tournament: self, points: t_player.points, playing_black: t_player.playing_black, blacklisted: t_player.blacklisted)
#      Standing.create_or_update(tournament: self, round: current_round, tournaments_player: t_player, points: t_player.points, 
#                                playing_black: t_player.playing_black, blacklisted: t_player.blacklisted)
    end
  end

  def all_boards_finished? round
    not boards.find_by(result: nil, round: round)
  end

  def any_board_finished? round
    boards.where(round:round).where.not(white: nil).where.not(black: nil).where.not(result: nil).size > 0
  end

  alias :start :finalize_round

  protected
  def all_boards_finished
    Rails.logger.debug(">>>>>>> all_boards_finished called")
    if boards.find_by(result: nil, round: completed_round)
      errors.add(:completed_round, "All boards must have finished first")
    end
  end

  private
  def create_past_event
    PastEvent.create(eventable: self)
  end

  def delete_past_event
    past_event = PastEvent.where(eventable: self).first
    past_event.destroy if past_event
  end
end
