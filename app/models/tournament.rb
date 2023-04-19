class Tournament < ApplicationRecord
  has_many :boards
  
  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players

  def next_round
    last_board = boards.order(:round).last
    last_board ? last_board.round + 1 : 1
  end

  def generate_pairings
    my_players = tournaments_players.map {|e| MyPlayer.new(e.player.id, e.name, e.rating, e.points)}
    pairs = Swissper.pair(my_players, delta_key: :tournament_points)

    round = next_round

    sorted_boards = pairs.sort_by do |board|
      if board.any? {|e| not e.is_a? MyPlayer}
        -1
      else
        board.sum {|e| e.tournament_points}
      end
    end.reverse

    sorted_boards.each do |board|
      w_player, b_player = board.map do |e|
        unless e.is_a? MyPlayer
          nil
        else
          Player.find(e.ar_id)
        end
      end
      # create board pairing for this round
      Board.create!(tournament: self, round: round, white: w_player, black: b_player)
    end
  end
end
