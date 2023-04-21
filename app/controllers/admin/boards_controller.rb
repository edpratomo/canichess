class Admin::BoardsController < ApplicationController
  before_action :set_admin_board, only: %i[ show edit update destroy ]
  before_action :set_tournament_round, only: %i[ index_by_round ]

  def index_by_round
    @boards = Board.where(tournament: @tournament, round: @round).order(:number)
  end

  # GET /admin/boards or /admin/boards.json
  def index
    @admin_boards = Admin::Board.all
  end

  # GET /admin/boards/1 or /admin/boards/1.json
  def show
  end

  # GET /admin/boards/new
  def new
    @admin_board = Admin::Board.new
  end

  # GET /admin/boards/1/edit
  def edit
  end

  # POST /admin/boards or /admin/boards.json
  def create
    @admin_board = Admin::Board.new(admin_board_params)

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
      if @admin_board.update(admin_board_params)
        format.html { redirect_to admin_board_url(@admin_board), notice: "Board was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_board }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_board.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/boards/1 or /admin/boards/1.json
  def destroy
    @admin_board.destroy

    respond_to do |format|
      format.html { redirect_to admin_boards_url, notice: "Board was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_board
      @admin_board = Admin::Board.find(params[:id])
    end

    def set_tournament_round
      @tournament = Tournament.find(params[:tournament_id])
      @round = params[:round_id]
    end

    # Only allow a list of trusted parameters through.
    def admin_board_params
      params.require(:admin_board).permit(:tournament_id, :round_id)
    end
end
