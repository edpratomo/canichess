class Api::V1::DeviceTokensController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    DeviceToken.find_or_create_by!(
      fcm_token: params[:fcm_token],
      platform: "android"
    )
    head :ok
  end
end
