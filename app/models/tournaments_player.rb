class TournamentsPlayer < ApplicationRecord
  belongs_to :tournament
  belongs_to :player
  belongs_to :group

  has_many :standings

  before_destroy :check_already_started, if: :swiss_system?

  def prev_opps
    black_opps = Board.where(tournament: tournament, white: self).map {|e| e.black}
    white_opps = Board.where(tournament: tournament, black: self).map {|e| e.white}
    black_opps | white_opps
  end

  def result_against opponent
    board = Board.find_by(group: group, white: self, black: opponent)
    if board
      if board.result == 'white'
        return :won
      elsif board.result == 'black'
        return :lost
      elsif board.result == 'draw'
        return :draw
      end
    else
      board = Board.find_by(group: group, white: opponent, black: self)
      if board
        if board.result == 'white'
          return :lost
        elsif board.result == 'black'
          return :won
        elsif board.result == 'draw'
          return :draw
        end
      end
    end
  end

  def games
    Board.where(group: group, white: self).or(Board.where(group: group, black: self)).order(:round)
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
    player.canisian?
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

  def swiss_system?
    group and group.is_swiss_system?
  end

  def check_already_started
    if group.current_round > 0
      errors.add :base, 'Tournament already started. Could not delete player.'
      throw :abort
    end
  end
end
