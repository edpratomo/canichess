class TournamentsPlayer < ApplicationRecord
  belongs_to :tournament
  belongs_to :player
  has_many :standings

  def prev_opps
    black_opps = Board.where(tournament: tournament, white: self).map {|e| e.black}
    white_opps = Board.where(tournament: tournament, black: self).map {|e| e.white}
    black_opps | white_opps
  end

  def games
    Board.where(tournament: tournament, white: self).or(Board.where(tournament: tournament, black: self)).order(:round)
  end

  def playing_black
    Board.where(tournament: tournament, black: self).size
  end

  def prev_color
    
  end

  def name
    player.name
  end

  def rating
    player.rating
  end
end
