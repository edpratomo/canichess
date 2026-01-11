class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception, if: Proc.new { |c| c.request.format != 'application/json' }
  #protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  before_action :check_redirect_key
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  layout :set_layout

  def set_layout
    if current_user
      'application'
    else
      #'devise'
      'plain'
    end
  end

  protected

  def after_sign_out_path_for(resource_or_scope)
    # Define the path you want users to be redirected to after sign out
    # For example, redirect to the sign-in page:
    new_user_session_path
  end
  
  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me, :fullname]
    devise_parameter_sanitizer.permit :sign_in, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  def check_redirect_key
    return unless ENV['ACCESS_KEY']
    if request[:access_key] != ENV['ACCESS_KEY'] && cookies[:access_key] != ENV['ACCESS_KEY']
      redirect_to "/404.html"
    elsif request[:access_key] == ENV['ACCESS_KEY']
      cookies.permanent[:access_key] = ENV['ACCESS_KEY']
    end
  end
end
