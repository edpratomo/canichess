class TournamentsPlayer < ApplicationRecord
  belongs_to :tournament
  belongs_to :player
  belongs_to :group, optional: true

  has_many :standings

  before_destroy :check_already_started

  def prev_opps
    black_opps = Board.where(tournament: tournament, white: self).map {|e| e.black}
    white_opps = Board.where(tournament: tournament, black: self).map {|e| e.white}
    black_opps | white_opps
  end

  def games
    Board.where(tournament: tournament, white: self).or(Board.where(tournament: tournament, black: self)).order(:round)
  end

  def playing_black round=nil
    if round
      Board.where(tournament: tournament, black: self, round: round).size # increment for this round
    else
      Board.where(tournament: tournament, black: self).size # for all rounds
    end
  end

  def prev_color
    
  end

  def name
    player.name
  end

  def alumni?
    player.affiliation == 'alumni'
  end

  def student?
    player.affiliation == 'student'
  end

  def canisian?
    player.affiliation == 'student' || player.affiliation == 'alumni'
  end

  def rating
    player.rating
  end

  def games_played
    player.games_played
  end

  def rated_games_played
    player.rated_games_played
  end

  def check_already_started
    if tournament.current_round > 0
      errors.add 'Tournament already started. Could not delete player.'
      throw :abort
    end
  end
end
