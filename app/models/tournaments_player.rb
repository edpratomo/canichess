class TournamentsPlayer < ApplicationRecord
  attr_accessor :exclude

  belongs_to :tournament
  belongs_to :player
  has_many :standings

  def name
    player.name
  end

  def rating
    player.rating
  end
end
