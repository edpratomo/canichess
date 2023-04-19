class Player < ApplicationRecord
  has_many :tournaments_players
  has_many :tournaments, through: :tournaments_players
  
  validates :rating, numericality: {only_integer: true}
end
