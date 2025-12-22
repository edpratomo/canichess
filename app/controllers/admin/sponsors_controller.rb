class Admin::SponsorsController < ApplicationController
  before_action :set_admin_sponsor, only: %i[ show edit update destroy ]

  # GET /admin/sponsors or /admin/sponsors.json
  def index
    @admin_sponsors = Sponsor.all.order(created_at: :desc)
  end

  # GET /admin/sponsors/1 or /admin/sponsors/1.json
  def show
  end

  # GET /admin/sponsors/new
  def new
    @admin_sponsor = Sponsor.new
  end

  # GET /admin/sponsors/1/edit
  def edit
  end

  # POST /admin/sponsors or /admin/sponsors.json
  def create
    @admin_sponsor = Sponsor.new(admin_sponsor_params)

    respond_to do |format|
      if @admin_sponsor.save
        format.html { redirect_to admin_sponsor_url(@admin_sponsor), notice: "Sponsor was successfully created." }
        format.json { render :show, status: :created, location: @admin_sponsor }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_sponsor.errors, status: :unprocessable_entity }
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
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_sponsor
      @admin_sponsor = Sponsor.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_sponsor_params
      params.fetch(:sponsor, {}).permit(:name, :remark, :logo, :url)
    end
end
