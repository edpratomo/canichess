class Player < ApplicationRecord
  has_many :tournaments_players
  has_many :tournaments, through: :tournaments_players

  has_many :simuls_players

  alias_attribute :volatility, :rating_volatility
  
  validates :rating, numericality: {only_integer: true}

  def tournament_points(tournament)
    tourney_player = tournaments_players.find_by(tournament: tournament)
    tourney_player.points if tourney_player
  end
end
