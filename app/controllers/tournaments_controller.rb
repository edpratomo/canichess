class TournamentsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_tournament

  layout 'top-nav.html.erb'

  def show
  end

  def pairings_by_round
    boards_per_round = @tournament.boards_per_round
    if boards_per_round > 15
      half_of_boards = (boards_per_round.to_f / 2).ceil
      @boards_1 = Board.where(tournament: @tournament, round: @round).order(:number).limit(half_of_boards)
      @boards_2 = Board.where(tournament: @tournament, round: @round).order(:number).offset(half_of_boards)
    else
      @boards_1 = Board.where(tournament: @tournament, round: @round).order(:number)
      @boards_2 = []
    end
    respond_to do |format|
      format.html { render :pairings }
      format.json { render :pairings, layout: false }
    end
  end

  def standings_by_round
    @standings = @tournament.sorted_standings(@round)
    respond_to do |format|
      format.html { render :standings }
      format.json { render :standings, layout: false }
    end
  end

  private
  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def set_round
    @round = params[:id].to_i
  end

  def set_tournament_player
    @tournament_player = TournamentsPlayer.find(params[:id])
  end
end
