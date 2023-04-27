class Tournament < ApplicationRecord
  has_many :boards
  has_many :standings

  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players

  validate :all_boards_finished, on: :update, if: :completed_round_changed?

  def compute_tiebreaks round=nil
    round ||= rounds
    t_players = tournaments_players.joins(:standings).where('standings.round': round).order('standings.points': :desc)
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
      
      # cumulative
      tb_cumulative = t_player.standings.where(round: (1..round).to_a).map(&:points).sum

      # update standing for t_player
      standing.update!(median: tb_modified_median, solkoff: tb_solkoff, cumulative: tb_cumulative)
    end
  end

  def finalize_round
    transaction do
      update!(completed_round: completed_round + 1)
      snapshoot_points
      if completed_round < rounds
        generate_pairings
      end
    end
  end

  def current_round
    last_board = boards.order(:round).last
    last_board ? last_board.round : 0
  end

  def next_round
    current_round + 1
  end

  # must add validation that previous round must be completed
  def generate_pairings
    # mapping AR instances to MyPlayer instances
    ar_my_players = tournaments_players.inject({}) do |m,o|
      m[o.id] = MyPlayer.new(o.id, o.name, o.rating, o.points)
      m
    end

    # add excluded players
    ar_my_players.each do |k,my_player|
      t_player = TournamentsPlayer.find(k)
      my_player.exclude = t_player.prev_opps.map {|e| e.nil? ? Swissper::Bye : ar_my_players[e.id] }
    end

    pairs = Swissper.pair(ar_my_players.values, delta_key: :tournament_points)

    round = next_round

    sorted_boards = pairs.sort_by do |pair|
      if pair.any? {|e| not e.is_a? MyPlayer}
        -1
      else
        pair.sum {|e| e.tournament_points}
      end
    end.reverse

    sorted_boards.each_with_index do |pair, idx|
      # convert back to AR instances
      player_1, player_2 = pair.map do |e|
        unless e.is_a? MyPlayer
          nil
        else
          TournamentsPlayer.find(e.ar_id)
        end
      end

      if [player_1, player_2].any? {|e| e.nil?}
        Board.create!(tournament: self, number: idx + 1, round: round, white: player_1, black: player_2)
      else
        # create board pairing for this round, taking into account the player's playing_black
        w_player, b_player = if player_1.playing_black > player_2.playing_black
          [player_1, player_2]
        else
          [player_2, player_1]
        end
        Board.create!(tournament: self, number: idx + 1, round: round, white: w_player, black: b_player)
      end
    end
  end

  def snapshoot_points
    return if current_round < 1
    tournaments_players.each do |t_player|
      Standing.create!(tournament: tournament, round: current_round, tournaments_player: t_player, points: t_player.points)
    end
  end

  protected
  def all_boards_finished
    Rails.logger.debug(">>>>>>> all_boards_finished called")
    if boards.find_by(result: nil, round: completed_round)
      errors.add(:completed_round, "All boards must have finished first")
    end
  end
end
