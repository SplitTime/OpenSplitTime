class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, except: :index
  after_action :verify_authorized

  def index
    authorize User
    params[:sort] ||= 'date_desc'
    respond_to do |format|
      format.html do
        @users = User.search(params[:search])
                     .sort(params[:sort])
                     .paginate(page: params[:page], per_page: 25)
      end
      format.csv do
        @users = User.all
        csv_stream = render_to_string(partial: 'users.csv.ruby')
        send_data(csv_stream, type: 'text/csv', filename: "users-#{Date.today}.csv")
      end
    end
  end

  def show
    authorize @user
  end

  def edit_preferences
    authorize @user
  end

  def update_preferences
    authorize @user
    if @user.update(permitted_params)
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

  def add_interest
    authorize @user
    participant = Participant.friendly.find(params[:participant])
    @user.add_interest(participant)
    redirect_to participants_path(search: params[:search], page: params[:page])
  end

  def remove_interest
    authorize @user
    participant = Participant.friendly.find(params[:participant])
    @user.remove_interest(participant)
    redirect_to participants_path(search: params[:search], page: params[:page])
  end

  private

  def secure_params
    params.require(:user).permit(:role)
  end

  def set_user
    @user = User.friendly.find(params[:id])
  end
end
