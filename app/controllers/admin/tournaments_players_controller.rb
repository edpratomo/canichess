class Admin::TournamentsPlayersController < ApplicationController
  before_action :set_admin_tournaments_player, only: %i[ show edit update destroy ]
  before_action :set_tournament, only: %i[ index_by_tournament index_by_group new upload create_preview preview ]
  before_action :set_group, only: %i[ index_by_group ]
  before_action :redirect_cancel, only: [:create, :update ]

  # GET /admin/tournaments_players or /admin/tournaments_players.json
  def index_by_tournament
    logger.debug("tournament: #{@tournament}")
    @tournaments_players = TournamentsPlayer.joins(:player).where(tournament: @tournament).order(:group_id, name: :asc)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def index_by_group
    @tournaments_players = TournamentsPlayer.joins(:player).where(tournament: @tournament, group: @group).order(name: :asc)
    respond_to do |format|
      format.html { render :index_by_tournament }
      format.js
    end
  end

  # GET /admin/tournaments_players/1 or /admin/tournaments_players/1.json
  def show
    @games = @tournaments_player.games
  end

  # GET /admin/tournaments_players/new
  def new
    @tournaments_player = TournamentsPlayer.new
    @groups = @tournament.groups.order(:name).map { |g| [g.name, g.id] }
  end

  # GET /admin/tournaments_players/1/edit
  def edit
  end

  # GET upload -> PATCH create_preview -> GET preview -> PATCH update_players
  def upload
  end

  def preview
    @new_players = session[:new_players]
    @selected = session[:selected]
    @groups = session[:groups]
  end

  # POST
  def create_preview
    groups = []
    new_players = []
    selected = []
    registered_players = @tournament.players.inject({}) {|m,o| m[o.id] = true; m}
    if tournament_params[:players_file]
      File.foreach(tournament_params[:players_file].path).with_index do |line, index|
        name, group_name = line.split(',').map &:strip
        next if name.empty?
        group_name ||= "Default Group"
        group = Group.find_by(tournament: @tournament, name: group_name)
        suggestions = Player.fuzzy_search(name: name)

        if suggestions.size == 1
          selected.push suggestions.first.id
        elsif suggestions.size > 1
          exact_match_suggestions = suggestions.select {|sugg| sugg.name.match(name)}
          if exact_match_suggestions.count == 1
            selected.push exact_match_suggestions.first.id
          else
            selected.push 0
          end
        else
          selected.push 0
        end

        groups.push group.id if group
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
    session[:groups] = groups

    redirect_to preview_admin_tournaments_players_path(@tournament)
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
    @tournaments_player.destroy

    respond_to do |format|
      if @tournaments_player.destroy
        format.html { redirect_to tournament_admin_tournaments_players_url(@tournaments_player.tournament),
                      notice: "Tournaments player was successfully destroyed." }
        format.json { head :ok, status: :ok }
      else
        format.html { redirect_to tournament_admin_tournaments_players_url(@tournaments_player.tournament),
                      alert: "Failed to remove tournament player." }
        format.json { head :no_content, status: :unprocessable_entity }
      end
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

    def set_group
      @group = Group.find(params[:group_id])
    end

    # Only allow a list of trusted parameters through.
    def admin_tournaments_player_params
      #params.fetch(:tournaments_player, {})
      params.require(:tournaments_player).permit(:blacklisted, :group_id)
    end

    def tournament_params
      params.require(:tournament).permit(:players_file, tournaments_players: [])
    end

    def redirect_cancel
      redirect_to admin_tournament_path(params[:id]) if params[:cancel]
    end
end
