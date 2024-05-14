class Admin::PlayersController < ApplicationController
  before_action :set_admin_player, only: %i[ show edit update destroy ]

  def suggestions
    @admin_players = Player.fuzzy_search(name: params[:q])
    render :layout => 'plain'
  end

  # GET /admin/players or /admin/players.json
  def index
    @admin_players = Player.all.order(:id)
  end

  # GET /admin/players/1 or /admin/players/1.json
  def show
  end

  # GET /admin/players/new
  def new
    @admin_player = Player.new
  end

  # GET /admin/players/1/edit
  def edit
  end

  # POST /admin/players or /admin/players.json
  def create
    @admin_player = Player.new(admin_player_params)

    respond_to do |format|
      if @admin_player.save
        format.html { redirect_to admin_player_url(@admin_player), notice: "Player was successfully created." }
        format.json { render :show, status: :created, location: @admin_player }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/players/1 or /admin/players/1.json
  def update
    respond_to do |format|
      if @admin_player.update(admin_player_params)
        format.html { redirect_to admin_player_url(@admin_player), notice: "Player was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_player }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/players/1 or /admin/players/1.json
  def destroy
    @admin_player.destroy

    respond_to do |format|
      format.html { redirect_to admin_players_url, notice: "Player was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_player
      @admin_player = Player.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_player_params
      params.require(:player).permit(:name, :rating, :fide_id, :email, :phone, :graduation_year, :affiliation, :remarks)
    end
end
