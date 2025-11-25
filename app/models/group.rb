class Group < ApplicationRecord
  has_many :boards
  has_many :tournaments_players
  has_many :players, through: :tournaments_players
  belongs_to :tournament, optional: true

  validates :rounds, presence: true, if: :is_swiss_system?

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

  #def rounds
  #  boards.pluck(:round).max || 0
  #end

  def boards_per_round
    boards.where(round: 1).count
  end

  def current_round
    raise NotImplementedError, "Subclasses must implement current_round method"
  end

  def next_round
    current_round + 1
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
