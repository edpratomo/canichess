class TournamentsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_tournament, except: %i[ player ]
  before_action :set_round, only: %i[ pairings_by_round pairings_by_group standings_by_round standings_by_group]
  before_action :set_groups, only: %i[ show players pairings_by_round standings_by_round pairings_by_group groups]
  before_action :set_group, only: %i[ pairings_by_group group_show standings_by_group players_in_group ]
  before_action :set_tournament_player, only: %i[ player ]

  layout 'top-nav.html.erb'

  helper_method :params
  
  def groups
    respond_to do |format|
      format.json { render :groups, layout: false}
    end
  end

  def group_show
  end

  def show
    if @tournament.groups.count == 1
      redirect_to group_show_tournaments_path(@tournament, @tournament.groups.first)
    end
  end

  def players
    num_players = @tournament.tournaments_players.count
    if num_players > 15
      @half_of_players = (num_players.to_f / 2).ceil
      @players_1 = @tournament.tournaments_players.joins(:player).order(:name).limit(@half_of_players)
      @players_2 = @tournament.tournaments_players.joins(:player).order(:name).offset(@half_of_players)
    else
      @players_1 = @tournament.tournaments_players.joins(:player).order(:name)
      @players_2 = []
    end
  end

  def players_in_group
    num_players = @group.tournaments_players.count
    if num_players > 15
      @half_of_players = (num_players.to_f / 2).ceil
      @players_1 = @group.tournaments_players.joins(:player).order(:name).limit(@half_of_players)
      @players_2 = @group.tournaments_players.joins(:player).order(:name).offset(@half_of_players)
    else
      @players_1 = @group.tournaments_players.joins(:player).order(:name)
      @players_2 = []
    end
  end

  def player
    @games = @tournament_player.games
    @group = @tournament_player.group
  end

  def pairings_by_round
    #if @tournament.groups.count > 1
    #  redirect_to group_pairings_tournaments_path(@front_page)
    #end
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
      format.html { render :pairings, layout: params[:full] == "1" ? 'pairing-plain' : 'pairing' }
      format.json { render :pairings, layout: false }
    end
  end

  def pairings_by_group
    if @round > @group.current_round
      redirect_to group_pairings_tournaments_path(@tournament, @group, @group.current_round)
      return
    end

    boards_per_round = @group.boards_per_round
    if boards_per_round > 15
      half_of_boards = (boards_per_round.to_f / 2).ceil
      @boards_1 = Board.where(tournament: @tournament, group: @group, round: @round).order(:number).limit(half_of_boards)
      @boards_2 = Board.where(tournament: @tournament, group: @group, round: @round).order(:number).offset(half_of_boards)
    else
      @boards_1 = Board.where(tournament: @tournament, group: @group, round: @round).order(:number)
      @boards_2 = []
    end

    #respond_to do |format|
    #  format.html { render :pairings_by_group, layout: 'pairing' }
    #  format.json { render :pairings_by_group, layout: false }
    #end
  end

  def standings_by_round
    @standings = @tournament.sorted_standings(@round)
    respond_to do |format|
      format.html { render :standings }
      format.json { render :standings, layout: false }
    end
  end

  def standings_by_group
    if @round > @group.completed_round
      redirect_to group_standings_tournaments_path(@tournament, @group, @group.completed_round)
      return
    end
    @standings = @group.sorted_standings(@round)
  end

  private
  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def set_round
    @round = params[:round_id].to_i
  end

  def set_groups
    @groups = @tournament.groups
  end

  def set_group
    @group = @tournament.groups.find(params[:group_id])
  end

  def set_tournament_player
    @tournament_player = TournamentsPlayer.find(params[:player_id])
    @tournament = @tournament_player.tournament
  end
end
