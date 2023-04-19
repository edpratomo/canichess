class Board < ApplicationRecord
  belongs_to :tournament
  belongs_to :white, class_name: 'Player', optional: true
  belongs_to :black, class_name: 'Player', optional: true

  def winner
    return nil if result == 'draw'
    return white if result == 'white'
    return black if result == 'black'
  end
end
