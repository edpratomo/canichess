class Tournament < ApplicationRecord
  has_many :boards
  
  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players

  validate :all_boards_finished, on: :update, if: :completed_round_changed?

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
    my_players = tournaments_players.map {|e| MyPlayer.new(e.player.id, e.name, e.rating, e.points)}
    pairs = Swissper.pair(my_players, delta_key: :tournament_points)

    round = next_round

    sorted_boards = pairs.sort_by do |board|
      if board.any? {|e| not e.is_a? MyPlayer}
        -1
      else
        board.sum {|e| e.tournament_points}
      end
    end.reverse

    sorted_boards.each_with_index do |board, idx|
      w_player, b_player = board.map do |e|
        unless e.is_a? MyPlayer
          nil
        else
          Player.find(e.ar_id)
        end
      end
      # create board pairing for this round
      Board.create!(tournament: self, number: idx + 1, round: round, white: w_player, black: b_player)
    end
  end

  def snapshoot_points
    tournaments_players.each do |t_player|
      Standing.create!(round: current_round, tournaments_player: t_player, points: t_player.points)
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
