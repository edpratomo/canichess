class Group < ApplicationRecord
  has_many :boards
  has_many :tournaments_players
  has_many :players, through: :tournaments_players
  belongs_to :tournament, optional: true

  def rounds
    boards.pluck(:round).max || 0
  end

  def boards_per_round
    boards.where(round: 1).count
  end

  def current_round
    tournament.current_round_rr(self)
  end

  def completed_round
    tournaments_players.joins(:standings).pluck(:round).max || 0
  end

  def all_boards_finished? round
    not boards.find_by(result: nil, round: round)
  end

  def any_board_finished? round
    boards.where(round:round).where.not(white: nil).where.not(black: nil).where.not(result: nil).size > 0
  end
end
