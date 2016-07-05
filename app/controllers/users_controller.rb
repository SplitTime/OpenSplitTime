class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit_preferences, :update_preferences, :destroy]
  after_action :verify_authorized

  def index
    params[:sort] ||= 'id'
    @users = User.search(params[:search])
                 .sort(params[:sort])
                 .paginate(page: params[:page], per_page: 25)
    authorize User
  end

  def show
    authorize @user
  end

  def edit_preferences
    authorize @user
  end

  def update_preferences
    authorize @user
    if @user.update(prefs_secure_params)
      redirect_to params[:referrer_path] || user_path(@user), :notice => "Preferencs updated."
    else
      redirect_to params[:referrer_path] || user_path(@user), :alert => "Unable to update preferences."
    end
  end

  def update
    authorize @user
    if @user.update(secure_params)
      redirect_to users_path, :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end

  def destroy
    authorize @user
    @user.destroy
    redirect_to users_path, :notice => "User deleted."
  end

  private

  def secure_params
    params.require(:user).permit(:role)
  end

  def prefs_secure_params
    params.require(:user).permit(:pref_distance_unit, :pref_elevation_unit)
  end

  def set_user
    @user = User.find(params[:id])
  end

end
