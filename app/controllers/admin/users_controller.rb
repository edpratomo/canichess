class Admin::UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  def index
    @users = User.order(:id)
  end

  def new
    @user = User.new
  end

  def edit
  end

  def update
    success = if password_blank?
      @user.update(user_params.except(:username, :password, :password_confirmation))
    else
      @user.update(user_params.except(:username))
    end

    respond_to do |format|
      if success
        format.html { redirect_to admin_users_url, notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "User created successfully"
    else
      render :new
    end
  end

  def show
  end

private
  def password_blank?
    user_params[:password].blank? && user_params[:password_confirmation].blank?
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:username, :fullname, :email, :password, :password_confirmation).tap do |whitelisted|
      if whitelisted[:password].empty?
        whitelisted.delete(:password)
      end
    end
  end
end
