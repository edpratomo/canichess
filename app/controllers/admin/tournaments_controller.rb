class Admin::TournamentsController < ApplicationController
  before_action :set_admin_tournament, only: %i[ show edit update destroy start update_players ]
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
    @admin_tournament = Tournament.new(admin_tournament_params)
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

  def update_players
    player_id = admin_tournament_params[:player_id]
    player_name = admin_tournament_params[:player_name]
    if player_id and not player_id.empty?
      @admin_tournament.add_player(id: player_id)
    elsif player_name and not player_name.empty?
      @admin_tournament.add_player(name: player_name)
    end

#    player_ids = [admin_tournament_params[:player_id]].compact.reject {|e| e.empty? }
    player_ids = []
    if admin_tournament_params[:player_ids] and not admin_tournament_params[:player_ids].empty?
      player_ids.concat admin_tournament_params[:player_ids].values.reject {|e| e == "0"}
    end
    player_names = []
#    player_names = [admin_tournament_params[:player_name]].compact.reject {|e| e.empty? }
    if admin_tournament_params[:player_names] and not admin_tournament_params[:player_names].empty?
      player_names.concat admin_tournament_params[:player_names].reject {|e| e.empty? }
    end

    # register players already known in our database
    registered_players = @admin_tournament.players.inject({}) {|m,o| m[o.id] = true; m}
    player_ids.map {|e| e.to_i}.reject {|e| registered_players[e]}.each do |player_id|
      @admin_tournament.add_player(id: player_id)
    end
    # register new players not in our database
    player_names.each do |player_name|
      @admin_tournament.add_player(name: player_name)
    end

    # delete sessions
    session.delete(:new_players)
    session.delete(:selected)

    # redirect
    respond_to do |format|
      format.html { redirect_to tournament_admin_tournaments_players_url(@admin_tournament), notice: "Tournament players were successfully updated." }
    end
  end

  # PATCH/PUT /admin/tournaments/1 or /admin/tournaments/1.json
  def update
    respond_to do |format|
      if @admin_tournament.update(admin_tournament_params.except(:players_file, :player_name, :player_id))
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
      params.require(:tournament).
             permit(:name, :fp, :rounds, :players_file, :description, :location, :date, :rated,
                    :max_walkover, :player_name, :player_id, player_names: [], player_ids: {})
    end

    def redirect_cancel
      redirect_to admin_tournaments_path if params[:cancel]
    end
end
