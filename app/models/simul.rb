class Simul < ApplicationRecord
  include Eventable

  # polymorphic many-to-many:
  # tournaments <= events_sponsors => sponsors
  # simuls      <= events_sponsors => sponsors
  has_many :events_sponsors, :as => :eventable
  has_many :sponsors, :through => :events_sponsors, :as => :eventable

  has_many :simuls_players, dependent: :destroy
  has_many :players, through: :simuls_players

  def percentage_completion
    if players.count == 0
      0
    else
      (simuls_players.where.not(result: nil).count.to_f / players.count) * 100
    end
  end

  def add_player args
    if args[:id] # existing player
      players << Player.find(args[:id])
    elsif args[:name]
      players << Player.create!(name: args[:name])
    end
  end

end
