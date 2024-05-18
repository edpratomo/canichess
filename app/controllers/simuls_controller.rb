class SimulsController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :set_simul, only: %i[ show result ]

  layout 'top-nav.html.erb'

  def show
  end

  def result
    @players = @simul.simuls_players.order(:id)
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
