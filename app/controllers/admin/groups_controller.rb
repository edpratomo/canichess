class Admin::GroupsController < ApplicationController
  before_action :set_admin_group, only: %i[ show edit update destroy ]
  before_action :set_admin_tournament, only: %i[ new create update destroy ], if: :tournament_context?
  
  def tournament_context?
    params[:tournament_id].present?
  end

  # GET /admin/groups or /admin/groups.json
  def index
    @admin_groups = Group.all
  end

  # GET /admin/groups/1 or /admin/groups/1.json
  def show
  end

  # GET /admin/groups/new
  def new
    @admin_group = Group.new(tournament: @admin_tournament)
  end

  # GET /admin/groups/1/edit
  def edit
  end

  # POST /admin/groups or /admin/groups.json
  def create
    @admin_group = Group.new(group_params.merge(tournament: @admin_tournament))
    
    respond_to do |format|
      if @admin_group.save
        #@admin_tournament.groups << @admin_group
    
        format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @admin_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/groups/1 or /admin/groups/1.json
  def update_old
    respond_to do |format|
      if @admin_group.update(group_params)
        format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @admin_group.update(group_params(@admin_group.type))
        format.html { redirect_to group_show_admin_tournaments_url(@admin_group.tournament, @admin_group), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/groups/1 or /admin/groups/1.json
  def destroy
    @admin_group.destroy

    respond_to do |format|
      format.html { redirect_to admin_tournament_url(@admin_tournament), notice: "Group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_group
      @admin_group = Group.find(params[:id])
    end

    def set_admin_tournament
      @admin_tournament = Tournament.find(params[:tournament_id])
    end

    # Only allow a list of trusted parameters through.
    def admin_group_params
      params.fetch(:group, {}).permit(:name, :type, :win_point, :draw_point, :bye_point, 
                                      :rounds, :bipartite_matching, :tournament_id, :h2h_tb)
    end

    # STI params
    def group_params(type="Group")
      params.require(type.underscore.to_sym).
        permit(:name, :tournament_id, :description, :type, :rounds, 
               :win_point, :draw_point, :bye_point, :bipartite_matching,
               :h2h_tb).tap do |whitelisted|
        if params[type.underscore.to_sym][:bipartite_matching].to_i > 0
          whitelisted[:bipartite_matching] = Array.new(params[type.underscore.to_sym][:bipartite_matching].to_i) { |e| e + 1 }
        else
          whitelisted[:bipartite_matching] = []
        end
      end
    end
end
