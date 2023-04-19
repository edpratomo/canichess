class Tournament < ApplicationRecord
  has_many :boards
  
  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players
end
