class Simul < ApplicationRecord
  include Eventable

  has_many :simuls_players, dependent: :destroy
  has_many :players, through: :simuls_players
end
