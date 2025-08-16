class Group < ApplicationRecord
  has_many :boards
  has_many :tournaments_players
  belongs_to :tournament, optional: true

  def rounds
    boards.pluck(:round).max
  end

  def boards_per_round
    boards.where(round: 1).count
  end

  def current_round
    tournament.current_round(self)
  end

  def completed_round
    tournaments_players.joins(:standings).pluck(:round).max || 0
  end
end
