class Group < ApplicationRecord
  has_many :boards
  has_many :tournaments_players
  belongs_to :tournament, optional: true
end
