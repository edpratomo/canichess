class Admin::TournamentsController < ApplicationController
  before_action :set_admin_tournament, only: %i[ show edit update destroy start ]
  before_action :redirect_cancel, only: [:create, :update]

  def start
    respond_to do |format|
      if @admin_tournament.start
        format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Tournament was successfully started." }
        format.json { render :show, status: :ok, location: @admin_tournament }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /admin/tournaments or /admin/tournaments.json
  def index
    @admin_tournaments = Tournament.all.order(fp: :desc, id: :desc)
  end

  # GET /admin/tournaments/1 or /admin/tournaments/1.json
  def show
  end

  # GET /admin/tournaments/new
  def new
    @admin_tournament = Tournament.new
  end

  # GET /admin/tournaments/1/edit
  def edit
  end

  # POST /admin/tournaments or /admin/tournaments.json
  def create
    @admin_tournament = Tournament.new(admin_tournament_params.slice(:name, :rounds, :fp))
    if admin_tournament_params[:players_file]
      @admin_tournament.import_players(admin_tournament_params[:players_file])
    end
    respond_to do |format|
      if @admin_tournament.save
        format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Tournament was successfully created." }
        format.json { render :show, status: :created, location: @admin_tournament }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/tournaments/1 or /admin/tournaments/1.json
  def update
    logger.debug("players_file: #{admin_tournament_params[:players_file]}")
    if admin_tournament_params[:players_file]
      @admin_tournament.import_players(admin_tournament_params[:players_file])
    end
    respond_to do |format|
      if @admin_tournament.update(admin_tournament_params.slice(:name, :rounds, :fp))
        format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Tournament was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_tournament }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/tournaments/1 or /admin/tournaments/1.json
  def destroy
    @admin_tournament.destroy

    respond_to do |format|
      format.html { redirect_to admin_tournaments_url, notice: "Tournament was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_tournament
      @admin_tournament = Tournament.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_tournament_params
      #params.fetch(:tournament, {})
      params.require(:tournament).permit(:name, :fp, :rounds, :tournaments_players, :players_file)
    end

    def redirect_cancel
      redirect_to admin_tournaments_path if params[:cancel]
    end
end
