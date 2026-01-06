class Api::V1::EventSubscriptionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :set_tournament
  before_action :set_simul

  def create
    device_token = DeviceToken.find_or_create_by!(fcm_token: params[:token])

    EventSubscription.find_or_create_by!(
      device_token: device_token,
      eventable: @tournament || @simul
    )

    head :ok
  end

  def destroy
    device = DeviceToken.find_by(fcm_token: params[:token])

    EventSubscription.where(
      device_token: device_token,
      eventable: @tournament || @simul
    ).destroy_all if device_token

    head :ok
  end

  private
  def set_tournament
    @tournament = Tournament.find_by(params[:tournament_id])
  end

  def set_simul
    @simul = Simul.find_by(params[:simul_id])
  end
end
