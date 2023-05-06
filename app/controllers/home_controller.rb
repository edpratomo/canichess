class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'htab.html.erb'
  
  def index
    @tournament = Tournament.find_by(fp: true)
    half_of_boards = (@tournament.boards_per_round.to_f / 2).ceil
    @boards_1 = Board.where(tournament: @tournament, round: @tournament.current_round).order(:number).limit(half_of_boards)
    @boards_2 = Board.where(tournament: @tournament, round: @tournament.current_round).order(:number).offset(half_of_boards)
  end
end
