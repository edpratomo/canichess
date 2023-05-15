class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_tournament
  before_action :set_round, only: %i[ pairings_by_round standings_by_round ]
  before_action :set_tournament_player, only: %i[ player]

  layout 'top-nav.html.erb'
  
  def index
  end

  def player
    @games = @tournament_player.games
  end

  def pairings_by_round
    half_of_boards = (@tournament.boards_per_round.to_f / 2).ceil
    @boards_1 = Board.where(tournament: @tournament, round: @round).order(:number).limit(half_of_boards)
    @boards_2 = Board.where(tournament: @tournament, round: @round).order(:number).offset(half_of_boards)
    render :pairings
  end

  def standings_by_round
    @standings = @tournament.sorted_standings(@round)
    render :standings
  end

  def contact
  end

  private
  def set_tournament
    @tournament = Tournament.find_by(fp: true)
  end
  
  def set_round
    @round = params[:id].to_i
  end

  def set_tournament_player
    @tournament_player = TournamentsPlayer.find(params[:id])
  end
end
