class Admin::TournamentsController < ApplicationController
  before_action :set_admin_tournament, only: %i[ show edit update destroy start update_players groups create_group group_show finalize_round]
  before_action :redirect_cancel, only: [:create, :update]
  before_action :set_group, only: [:edit_group, :update_group, :create_group, :finalize_round, :start, :group_show ]
  before_action :redirect_cancel_players, only: [:update_players]

  def groups
    @groups = @admin_tournament.groups.order(:name)
    @group = Group.new(tournament: @admin_tournament)
    respond_to do |format|
      format.html # groups.html.erb
      format.json { render json: @groups }
    end
  end

  def edit_group

  end

  def update_group
    respond_to do |format|
      if @group.update(group_params(@group.type))
        format.html { redirect_to group_show_admin_tournaments_url(@group.tournament, @group), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_group
    @group = Group.new(tournament: @admin_tournament, name: group_params[:name], type: group_params[:type],
                       rounds: group_params[:rounds], 
                       win_point: group_params[:win_point], draw_point: group_params[:draw_point], 
                       bye_point: group_params[:bye_point])

    respond_to do |format|
      if @group.save
        format.html { redirect_to groups_admin_tournaments_url(@admin_tournament), notice: "Tournament group was successfully created." }
        format.json { render :show, status: :created, location: @admin_tournament }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_tournament.errors, status: :unprocessable_entity }
      end
    end
  end

#  def finalize_round_rr
#    round = params[:round_id].to_i
#    respond_to do |format|
#      if @admin_tournament.finalize_round_rr(@group, round)
#        format.html { redirect_to group_show_admin_tournaments_url(@admin_tournament, @group), notice: "Tournament was successfully updated." }
#        format.json { render :show, status: :ok, location: @admin_tournament }
#      else
#        format.html { render :edit, status: :unprocessable_entity }
#        format.json { render json: @admin_tournament.errors, status: :unprocessable_entity }
#      end
#    end
#  end

  def finalize_round
    round = params[:round_id].to_i
    respond_to do |format|
      if @group.finalize_round(@round)
        format.html { redirect_to group_show_admin_tournaments_url(@admin_tournament, @group), notice: "Tournament was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_tournament }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  def start
    retval =  @group.start
    respond_to do |format|
      if retval
        if @group
          format.html { redirect_to group_show_admin_tournaments_url(@admin_tournament, @group), notice: "Tournament group was successfully started." }
        else
          format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Tournament was successfully started." }
        end
        #format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Tournament was successfully started." }
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
    render :show_rr
  end

  def group_show

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
 #   group_id = admin_tournament_params[:group_id]
    group_id = admin_tournaments_player_params[:group_id]
    group = Group.find(group_id) if group_id and not group_id.empty?

    if player_id and not player_id.empty?
      @admin_tournament.add_player(id: player_id, group: group)
    elsif player_name and not player_name.empty?
      @admin_tournament.add_player(name: player_name, group: group)
    end

#    player_ids = [admin_tournament_params[:player_id]].compact.reject {|e| e.empty? }
    params_player_names = admin_tournament_params[:player_names].to_a.reject {|e| e.empty? }
    Rails.logger.debug("player names: #{params_player_names.inspect}")
    player_ids = []
    player_names = []
    if admin_tournament_params[:player_ids] and not admin_tournament_params[:player_ids].empty?
      player_ids_values = admin_tournament_params[:player_ids].values
      player_ids_values.each_with_index do |e,idx|
        if e == "0"
          player_names << [params_player_names.shift, admin_tournament_params[:group_ids][idx]]
        else
          player_ids << [e, admin_tournament_params[:group_ids][idx]]
        end
      end
    end

    # register players already known in our database
    registered_players = @admin_tournament.players.inject({}) {|m,o| m[o.id] = true; m}
    player_ids.map {|e| [e.first.to_i, e[1].to_i]}.reject {|e| registered_players[e.first]}.each do |player_id, group_id|
      @admin_tournament.add_player(id: player_id, group: Group.find(group_id))
    end
    # register new players not in our database
    player_names.each do |player_name, group_id|
      @admin_tournament.add_player(name: player_name, group: Group.find(group_id))
    end

    # delete sessions
    session.delete(:new_players)
    session.delete(:selected)
    session.delete(:groups)

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

    def set_group
      @group = Group.find(params[:group_id]) if params[:group_id]
    end

    # Only allow a list of trusted parameters through.
    def admin_tournament_params
      #params.fetch(:tournament, {})
      params.require(:tournament).
             permit(:name, :fp, :rounds, :players_file, :description, :location, :date, :rated, :system,
                    :max_walkover, :player_name, :player_id, player_names: [], player_ids: {}, group_ids: [])
    end

    def admin_tournaments_player_params
      params.require(:tournaments_player).permit(:group_id)
    end

    # STI params
    def group_params(type="Group")
      params.require(type.underscore.to_sym).
        permit(:name, :tournament_id, :description, :type, :rounds, 
               :win_point, :draw_point, :bye_point).tap do |whitelisted|
        if params[type.underscore.to_sym][:bipartite_matching].to_i > 0
          whitelisted[:bipartite_matching] = Array.new(params[type.underscore.to_sym][:bipartite_matching].to_i) { |e| e + 1 }
        else
          whitelisted[:bipartite_matching] = []
        end
      end
      #params.require(:group).permit(:name, :tournament_id, :description, :type, :rounds, :win_point, :draw_point, :bye_point)
    end

    def redirect_cancel
      redirect_to admin_tournaments_path if params[:cancel]
    end

    def redirect_cancel_players
      redirect_to admin_tournament_path(params[:id]) if params[:cancel]
    end

end
