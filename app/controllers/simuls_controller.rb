class SimulsController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :set_simul, only: %i[ show edit update destroy ]

  layout 'top-nav.html.erb'

  def show
    @players = @simul.simuls_players.order(:id) #'simuls_players.id')
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_simul
      @simul = Simul.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def simul_params
      params.fetch(:simul, {})
    end

end
