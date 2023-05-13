class Admin::TournamentsPlayersController < ApplicationController
  before_action :set_admin_tournaments_player, only: %i[ show edit update destroy ]
  before_action :set_tournament, only: %i[ index_by_tournament ]

  # GET /admin/tournaments_players or /admin/tournaments_players.json
  def index_by_tournament
    logger.debug("tournament: #{@tournament}")
#    @tournaments_players = TournamentsPlayer.joins(:player).where(tournament: @tournament).order(blacklisted: :asc, points: :desc, rating: :desc, name: :asc)
    @tournaments_players = TournamentsPlayer.joins(:player).where(tournament: @tournament).order(name: :asc)

    respond_to do |format|
      format.html
      format.js
    end

  end

  # GET /admin/tournaments_players/1 or /admin/tournaments_players/1.json
  def show
    @games = @tournaments_player.games
  end

  # GET /admin/tournaments_players/new
  def new
    @admin_tournaments_player = TournamentsPlayer.new
  end

  # GET /admin/tournaments_players/1/edit
  def edit
  end

  # POST /admin/tournaments_players or /admin/tournaments_players.json
  def create
    @admin_tournaments_player = TournamentsPlayer.new(admin_tournaments_player_params)

    respond_to do |format|
      if @admin_tournaments_player.save
        format.html { redirect_to admin_tournaments_player_url(@admin_tournaments_player), notice: "Tournaments player was successfully created." }
        format.json { render :show, status: :created, location: @admin_tournaments_player }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_tournaments_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/tournaments_players/1 or /admin/tournaments_players/1.json
  def update
    respond_to do |format|
      if @tournaments_player.update(admin_tournaments_player_params)
        format.html { redirect_to admin_tournaments_player_url(@tournaments_player), notice: "Tournaments player was successfully updated." }
        format.json { render :show, status: :ok, location: @tournaments_player }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_tournaments_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/tournaments_players/1 or /admin/tournaments_players/1.json
  def destroy
    @admin_tournaments_player.destroy

    respond_to do |format|
      format.html { redirect_to admin_tournaments_players_url, notice: "Tournaments player was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_tournaments_player
      @tournaments_player = TournamentsPlayer.find(params[:id])
    end

    def set_tournament
      @tournament = Tournament.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_tournaments_player_params
      #params.fetch(:tournaments_player, {})
      params.require(:tournaments_player).permit(:blacklisted)
    end
end
