class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_tournament
  before_action :set_round, only: %i[ pairings_by_round standings_by_round ]

  layout 'top-nav.html.erb'
  
  def index
    half_of_boards = (@tournament.boards_per_round.to_f / 2).ceil
    @round = @tournament.current_round
    @boards_1 = Board.where(tournament: @tournament, round: @round).order(:number).limit(half_of_boards)
    @boards_2 = Board.where(tournament: @tournament, round: @round).order(:number).offset(half_of_boards)
  end

  def pairings_by_round
    half_of_boards = (@tournament.boards_per_round.to_f / 2).ceil
    @boards_1 = Board.where(tournament: @tournament, round: @round).order(:number).limit(half_of_boards)
    @boards_2 = Board.where(tournament: @tournament, round: @round).order(:number).offset(half_of_boards)
    render :pairings
  end

  def standings_by_round
  
  end

  private
  def set_tournament
    @tournament = Tournament.find_by(fp: true)
  end
  
  def set_round
    @round = params[:id].to_i
  end
end
