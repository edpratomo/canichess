class Admin::SimulsPlayersController < ApplicationController
  before_action :set_admin_simuls_player, only: %i[ show edit update destroy update_result]
  before_action :set_simul, only: %i[ result index_by_simul new upload create_preview preview ]

  before_action :redirect_cancel, only: [:create, :update ]

  # GET /admin/simuls_players or /admin/simuls_players.json
  def index_by_simul
    @simuls_players = SimulsPlayer.joins(:player).where(simul: @simul).order(number: :asc)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def result
    @simuls_players = SimulsPlayer.joins(:player).where(simul: @simul).order(number: :asc)
  end

  def update_result
    result = if admin_simuls_player_params[:result] == "won"
      @simuls_player.color
    elsif admin_simuls_player_params[:result] == "lost"
      @simuls_player.color == "white" ? "black" : "white"
    else
      admin_simuls_player_params[:result]
    end

    respond_to do |format|
      if @simuls_player.update(result: result)
        format.html { redirect_to admin_simuls_player_url(@simuls_player), notice: "Simuls player was successfully updated." }
        format.json { render :show, status: :ok, location: admin_simuls_player_url(@simuls_player) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_simuls_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /admin/simuls_players/1 or /admin/simuls_players/1.json
  def show
  end

  # GET /admin/simuls_players/new
  def new
    @simuls_player = SimulsPlayer.new
  end

  # GET /admin/simuls_players/1/edit
  def edit
  end

  # GET upload -> PATCH create_preview -> GET preview -> PATCH update_players
  def upload
  end

  def preview
    @new_players = session[:new_players]
    @selected = session[:selected]
  end

  # POST
  def create_preview
    new_players = []
    selected = []
    registered_players = @simul.players.inject({}) {|m,o| m[o.id] = true; m}
    if simul_params[:players_file]
      File.foreach(simul_params[:players_file].path).with_index do |line, index|
        name = line.strip
        next if name.empty?
        suggestions = Player.fuzzy_search(name: name)

        if suggestions.size == 1
          selected.push suggestions.first.id
        else
          selected.push 0
        end
        new_players.push [[name, 0]].concat(suggestions.
            map do |e|
              registered_str = registered_players[e.id] ? " - registered" : ""
              ["#{e.name} (ID: #{e.id} Rtg: #{e.rating})" + registered_str, e.id]
            end
          )
      end
    end

    logger.debug(new_players)
    session[:new_players] = new_players
    session[:selected] = selected

    redirect_to preview_admin_simuls_players_path(@simul)
  end

  # POST /admin/simuls_players or /admin/simuls_players.json
  def create
    @admin_simuls_player = SimulsPlayer.new(admin_simuls_player_params)

    respond_to do |format|
      if @admin_simuls_player.save
        format.html { redirect_to admin_simuls_player_url(@admin_simuls_player), notice: "Simuls player was successfully created." }
        format.json { render :show, status: :created, location: @admin_simuls_player }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_simuls_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/simuls_players/1 or /admin/simuls_players/1.json
  def update
    respond_to do |format|
      if @simuls_player.update(admin_simuls_player_params)
        format.html { redirect_to admin_simuls_player_url(@simuls_player), notice: "Simuls player was successfully updated." }
        format.json { render :show, status: :ok, location: @simuls_player }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_simuls_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/simuls_players/1 or /admin/simuls_players/1.json
  def destroy
    @simuls_player.destroy

    respond_to do |format|
      if @simuls_player.destroy
        format.html { redirect_to simul_admin_simuls_players_url(@simuls_player.simul),
                      notice: "Simuls player was successfully destroyed." }
        format.json { head :ok, status: :ok }
      else
        format.html { redirect_to simul_admin_simuls_players_url(@simuls_player.simul),
                      alert: "Failed to remove simul player." }
        format.json { head :no_content, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_simuls_player
      @simuls_player = SimulsPlayer.find(params[:id])
    end

    def set_simul
      @simul = Simul.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_simuls_player_params
      params.require(:simuls_player).permit(:number, :color, :result)
    end

    def simul_params
      params.require(:simul).permit(:players_file, simuls_players: [])
    end

    def redirect_cancel
      redirect_to admin_simul_path(params[:id]) if params[:cancel]
    end

end
