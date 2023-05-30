class MyPlayer < Swissper::Player
  attr_accessor :rating, :rating_deviation, :volatility

  attr_reader :tournament_points
  attr_reader :name
  attr_reader :ar_id
  attr_reader :ar_obj

  def initialize ar_obj #id, name, rating, points
    @ar_obj = ar_obj # TournamentsPlayer.find(ar_id)

    @ar_id = ar_obj.id
    @rating_deviation = ar_obj.player.rating_deviation
    @volatiliy = ar_obj.player.rating_volatility
    @name = ar_obj.name
    @rating = ar_obj.rating
    @tournament_points = ar_obj.points
    super()
  end

  def save_rating
    @ar_obj.player.update!(rating: @rating.round, rating_deviation: @rating_deviation, rating_volatility: @volatility)
  end
end
