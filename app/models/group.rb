class Group < ApplicationRecord
  has_many :boards, dependent: :destroy
  has_many :tournaments_players
  has_many :players, through: :tournaments_players
  belongs_to :tournament #, optional: true
  belongs_to :merged_standings_config, optional: true

  validates :rounds, presence: true, if: :is_swiss_system?
  validate :check_all_boards_finished, on: :update, if: :completed_round_changed?

  def completed_round
    tournaments_players.joins(:standings).pluck(:round).max || 0
  end

  def is_finished?
    completed?
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

  def sufficient_players?
    raise NotImplementedError, "Subclasses must implement sufficient_players? method"
  end

  def current_round
    raise NotImplementedError, "Subclasses must implement current_round method"
  end

  def delete_round round
    raise NotImplementedError, "Subclasses must implement delete_round method"
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

  def broadcast_round_finished
    ActionCable.server.broadcast "round_finished", self.completed?
  end

  protected
  def check_all_boards_finished
    Rails.logger.debug(">>>>>>> all_boards_finished called")
    if boards.find_by(result: nil, round: completed_round)
      errors.add(:completed_round, "All boards must have finished first")
    end
  end

    # if a pair never met, return nil
  def compile_results_among_tied_players standings
    results = {}
    standings.combination(2).each do |std1, std2|
      p1 = std1.tournaments_player
      p2 = std2.tournaments_player

      res = p1.result_against(p2)
      return nil if res.nil?

      results[std1] ||= 0
      results[std2] ||= 0
      if res == :won
        results[std1] += win_point
      elsif res == :lost
        results[std2] += win_point
      elsif res == :draw
        results[std1] += draw_point
        results[std2] += draw_point
      end
    end
    results
  end

  def update_h2h round
    final_stds = self.tournament.standings.joins(tournaments_player: :player).
                  where('tournaments_players.group_id': self.id, round: round).
                  order(blacklisted: :asc, points: :desc)

    tied_points = final_stds.inject({}) do |m, std|
      m[std.points] ||= []
      m[std.points] << std
      m
    end.select {|k, v| v.size > 1 }

    tied_points.each do |points, stds|
      results = compile_results_among_tied_players(stds)
      next if results.nil? # a pair never met

      Rails.logger.debug("results: #{results.inspect}")
      results.each do |std, points|
        std.update(h2h_points: points, h2h_cluster: results.keys.count)
      end
    end
  end
end
