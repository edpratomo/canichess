require 'swissper'
require 'players_list'

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

class ActiveRecordPlayersList < PlayersList
  attr_reader :tournament, :ar_to_players

  def initialize tournament
    @tournament = tournament
    @tournaments_players = tournament.tournaments_players
    @ar_to_players = {}

    # mapping AR instances to MyPlayer instances
    @tournaments_players.where(blacklisted: false).each do |o|
      self.add(o)
    end
  end

  def add new_player
    @ar_to_players[new_player.id] = MyPlayer.new(new_player)
  end

  def update_exclusion
    @ar_to_players.each do |k,my_player|
      t_player = my_player.ar_obj
      my_player.exclude = t_player.prev_opps.map {|e| e.nil? ? Swissper::Bye : @ar_to_players[e.id] }
    end
  end

  def get
    ar_to_players.values
  end
end
