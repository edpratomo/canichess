class Admin::SponsorsController < ApplicationController
  before_action :set_admin_sponsor, only: %i[ show edit update destroy ]
  before_action :set_tournament, only: %i[ new create show ], if: :tournament_context?

  # GET /admin/sponsors or /admin/sponsors.json
  def index
    @admin_sponsors = Sponsor.all.order(created_at: :desc)
  end

  # GET /admin/sponsors/1 or /admin/sponsors/1.json
  def show
    @eventables = @admin_sponsor.eventables.order(:created_at)
  end

  # GET /admin/sponsors/new
  def new
    if @tournament
      @sponsors_selection = Sponsor.all.order(:name).pluck(:name, :id)
      render :add_sponsor
    else
      @admin_sponsor = Sponsor.new
    end
  end

  # GET /admin/sponsors/1/edit
  def edit
  end

  # POST /admin/sponsors or /admin/sponsors.json
  def create
    if @tournament
      sponsor = Sponsor.find(tournament_params[:sponsor_id])
      @tournament.sponsors << sponsor unless @tournament.sponsors.include?(sponsor)

      redirect_to admin_tournament_path(@tournament),
                notice: "Sponsor added to tournament"
    else
      @admin_sponsor = Sponsor.new(sponsor_params)

      if @admin_sponsor.save
        redirect_to admin_sponsor_path(@admin_sponsor), notice: "Sponsor was successfully created." 
      else
        render :new
      end
    end
  end

  # PATCH/PUT /admin/sponsors/1 or /admin/sponsors/1.json
  def update
    respond_to do |format|
      if @admin_sponsor.update(admin_sponsor_params)
        format.html { redirect_to admin_sponsor_url(@admin_sponsor), notice: "Sponsor was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_sponsor }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_sponsor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/sponsors/1 or /admin/sponsors/1.json
  def destroy
    @admin_sponsor.destroy

    respond_to do |format|
      format.html { redirect_to admin_sponsors_url, notice: "Sponsor was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def tournament_context?
      params[:tournament_id].present?
    end
  
      # Use callbacks to share common setup or constraints between actions.
    def set_admin_sponsor
      @admin_sponsor = Sponsor.find(params[:id])
    end

    def set_tournament
      @tournament = Tournament.find(params[:tournament_id])
    end

    def tournament_params
      params.fetch(:tournament, {}).permit(:sponsor_id)
    end

    # Only allow a list of trusted parameters through.
    def admin_sponsor_params
      params.fetch(:sponsor, {}).permit(:name, :remark, :logo, :url)
    end
end
