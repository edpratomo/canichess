class MyPlayer < Swissper::Player
  attr_accessor :tournament_points
  attr_accessor :name
  attr_accessor :rating
  attr_accessor :ar_id

  def initialize ar_id, name, rating, points
    @ar_id = ar_id
    @name = name
    @rating = rating
    @tournament_points = points
    super()
  end
end
