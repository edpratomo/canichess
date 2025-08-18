class Admin::BoardsController < ApplicationController
  before_action :set_admin_board, only: %i[ show edit update destroy ]
  before_action :set_tournament_round, only: %i[ index_by_round  delete_by_round index_by_group delete_by_group ]
  before_action :set_group, only: %i[ index_by_group delete_by_group ]

  def index_by_round
    @boards = Board.where(tournament: @tournament, round: @round).order(:number)
  end

  # GET /admin/boards or /admin/boards.json
  def index
    @boards = Board.all
  end

  def index_by_group
    @boards = Board.where(tournament: @tournament, round: @round, group: @group).order(:number)
  end

  # GET /admin/boards/1 or /admin/boards/1.json
  def show
  end

  # GET /admin/boards/new
  def new
    @board = Board.new
  end

  # GET /admin/boards/1/edit
  def edit
  end

  # POST /admin/boards or /admin/boards.json
  def create
    @board = Board.new(admin_board_params)

    respond_to do |format|
      if @admin_board.save
        format.html { redirect_to admin_board_url(@admin_board), notice: "Board was successfully created." }
        format.json { render :show, status: :created, location: @admin_board }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_board.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/boards/1 or /admin/boards/1.json
  def update
    respond_to do |format|
      if @board.update(admin_board_params)
        format.html { redirect_to admin_board_url(@board), notice: "Board was successfully updated." }
        format.json { render :show, status: :ok, location: @board }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_by_round
    ActiveRecord::Base.transaction do
      Board.where(tournament: @tournament, round: @round).delete_all
    end
    respond_to do |format|
      format.html { redirect_to admin_tournaments_url, notice: "Pairings for round #{@round} were successfully deleted." }
      format.json { head :no_content }
    end
  end

  def delete_by_group
    ActiveRecord::Base.transaction do
      Board.where(group: @group, round: @round).delete_all
    end
    respond_to do |format|
      format.html { redirect_to admin_tournaments_url, notice: "Pairings for round #{@round} were successfully deleted." }
      format.json { head :no_content }
    end
  end

  # DELETE /admin/boards/1 or /admin/boards/1.json
  def destroy
    @board.destroy

    respond_to do |format|
      format.html { redirect_to admin_boards_url, notice: "Board was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_board
      @board = Board.find(params[:id])
    end

    def set_tournament_round
      @tournament = Tournament.find(params[:tournament_id])
      @round = params[:round_id].to_i
    end

    def set_group
      @group = Group.find(params[:group_id])
    end

    # Only allow a list of trusted parameters through.
    def admin_board_params
      logger.debug(params)
      params.require(:board).permit(:result, :walkover)
    end
end
