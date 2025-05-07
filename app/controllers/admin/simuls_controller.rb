class Admin::SimulsController < ApplicationController
  before_action :set_admin_simul, only: %i[ show edit update destroy start update_players ]
  before_action :redirect_cancel, only: [:create, :update]
  before_action :redirect_cancel_players, only: [:update_players]

  # GET /admin/simuls or /admin/simuls.json
  def index
    @admin_simuls = Simul.all.order(fp: :desc, id: :desc)
  end

  # GET /admin/simuls/1 or /admin/simuls/1.json
  def show
  end

  # GET /admin/simuls/new
  def new
    @admin_simul = Simul.new
  end

  # GET /admin/simuls/1/edit
  def edit
  end

  # POST /admin/simuls or /admin/simuls.json
  def create
    @admin_simul = Simul.new(admin_simul_params)

    respond_to do |format|
      if @admin_simul.save
        format.html { redirect_to admin_simul_url(@admin_simul), notice: "Simul was successfully created." }
        format.json { render :show, status: :created, location: @admin_simul }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_simul.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_players
    player_id = admin_simul_params[:player_id]
    player_name = admin_simul_params[:player_name]
    if player_id and not player_id.empty?
      @admin_simul.add_player(id: player_id)
    elsif player_name and not player_name.empty?
      @admin_simul.add_player(name: player_name)
    end

    player_ids = []
    if admin_simul_params[:player_ids] and not admin_simul_params[:player_ids].empty?
      player_ids.concat admin_simul_params[:player_ids].values.reject {|e| e == "0"}
    end

    player_names = []
    if admin_simul_params[:player_names] and not admin_simul_params[:player_names].empty?
      player_names.concat admin_simul_params[:player_names].reject {|e| e.empty? }
    end

    # register players already known in our database
    registered_players = @admin_simul.players.inject({}) {|m,o| m[o.id] = true; m}
    player_ids.map {|e| e.to_i}.reject {|e| registered_players[e]}.each do |player_id|
      @admin_simul.add_player(id: player_id)
    end
    # register new players not in our database
    player_names.each do |player_name|
      @admin_simul.add_player(name: player_name)
    end

    # delete sessions
    session.delete(:new_players)
    session.delete(:selected)

    # redirect
    respond_to do |format|
      format.html { redirect_to simul_admin_simuls_players_url(@admin_simul), notice: "Simul players were successfully updated." }
    end
  end

  # PATCH/PUT /admin/simuls/1 or /admin/simuls/1.json
  def update
    respond_to do |format|
      if @admin_simul.update(admin_simul_params)
        format.html { redirect_to admin_simul_url(@admin_simul), notice: "Simul was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_simul }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_simul.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/simuls/1 or /admin/simuls/1.json
  def destroy
    @admin_simul.destroy

    respond_to do |format|
      format.html { redirect_to admin_simuls_url, notice: "Simul was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_simul
      @admin_simul = Simul.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_simul_params
      params.fetch(:simul, {}).permit(:name, :logo, :fp, :players_file,
                                       :description, :location, :date, :simulgivers,
                                       player_names: [], player_ids: {})
    end

    def redirect_cancel
      redirect_to admin_simuls_path if params[:cancel]
    end

    def redirect_cancel_players
      redirect_to admin_simul_path(params[:id]) if params[:cancel]
    end
  end
