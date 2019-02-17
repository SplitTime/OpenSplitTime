class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, except: :index
  after_action :verify_authorized

  def index
    authorize User
    users = User.with_avatar_names.includes(:avatar)
                .where(prepared_params[:filter])
                .search(prepared_params[:search])
                .order(prepared_params[:sort])
    paginated_users = users.paginate(page: prepared_params[:page], per_page: prepared_params[:per_page] || 25)

    @presenter = UsersCollectionPresenter.new(paginated_users, prepared_params, current_user)
    respond_to do |format|
      format.html
      format.csv do
        csv_stream = render_to_string(partial: 'users.csv.ruby', locals: {users: users})
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
      redirect_to params[:referrer_path] || user_path(@user), notice: 'Preferences updated.'
    else
      redirect_to params[:referrer_path] || user_path(@user), alert: 'Unable to update preferences.'
    end
  end

  def update
    authorize @user
    if @user.update(secure_params)
      redirect_to users_path, notice: 'User updated.'
    else
      redirect_to users_path, alert: 'Unable to update user.'
    end
  end

  def destroy
    authorize @user
    @user.destroy
    redirect_to users_path, notice: 'User deleted.'
  end

  def my_stuff
    authorize @user
    @presenter = MyStuffPresenter.new(@user)
  end

  private

  def secure_params
    params.require(:user).permit(:role)
  end

  def set_user
    @user = User.friendly.find(params[:id])
    redirect_numeric_to_friendly(@user, params[:id])
  end
end
