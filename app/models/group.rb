class Group < ApplicationRecord
  has_many :boards
  has_many :tournaments_players
  has_many :players, through: :tournaments_players
  belongs_to :tournament #, optional: true
  belongs_to :merged_standings_config, optional: true

  validates :rounds, presence: true, if: :is_swiss_system?

  def is_finished?
    completed_round == rounds
  end

  def is_swiss_system?
    type == 'Swiss'
  end

  def percentage_completion
    return 100 if completed_round == rounds
    return 0 if current_round == 0
    n_boards_per_round = boards_per_round
    total_boards = n_boards_per_round * rounds
    boards_finished_current_round = boards.where(round: current_round).where.not(result: nil).size
    (((n_boards_per_round * completed_round + boards_finished_current_round) * 100) / (n_boards_per_round * rounds)).floor 
  end

  def boards_per_round
    (players.size.to_f / 2).ceil
  end

  def current_round
    raise NotImplementedError, "Subclasses must implement current_round method"
  end

  def finalize_round round
    raise NotImplementedError, "Subclasses must implement finalize_round method"
  end

  def snapshoot_points round
    raise NotImplementedError, "Subclasses must implement snapshoot_points method"
  end

  def compute_tiebreaks round
    raise NotImplementedError, "Subclasses must implement compute_tiebreaks method"
  end
  
  def sorted_standings round=nil
    raise NotImplementedError, "Subclasses must implement sorted_standings method"
  end

  def sorted_merged_standings
    raise NotImplementedError, "Subclasses must implement sorted_merged_standings method"
  end
  
  def next_round
    current_round + 1
  end

  def update_ratings
    group_tournaments_players = tournaments_players

    group_boards = boards

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

  def update_total_games
    group_tournaments_players = tournaments_players

    group_tournaments_players.each do |t_player|
      games_played = t_player.games.reject {|e| e.contains_bye? }.size
      t_player.player.update!(games_played: t_player.games_played + games_played)
      if self.tournament.rated
        t_player.player.update!(rated_games_played: t_player.rated_games_played + games_played)
      end
    end
  end

  def all_boards_finished? round
    not boards.find_by(result: nil, round: round)
  end

  def any_board_finished? round
    boards.where(round:round).where.not(white: nil).where.not(black: nil).where.not(result: nil).size > 0
  end
end
