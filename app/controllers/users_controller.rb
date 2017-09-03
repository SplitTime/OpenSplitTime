class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, except: :index
  after_action :verify_authorized

  def index
    authorize User
    authorized_scope = policy_class::Scope.new(current_user, controller_class)
    working_scope = prepared_params[:editable] ? authorized_scope.editable : authorized_scope.viewable
    @resources = working_scope.where(prepared_params[:filter])
                     .search(prepared_params[:search])
                     .order(prepared_params[:sort])
    respond_to do |format|
      format.html do
        @resources = @resources.paginate(page: prepared_params[:page], per_page: prepared_params[:per_page])
      end
      format.csv do
        csv_stream = render_to_string(partial: 'users.csv.ruby', locals: {users: @resources})
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
      redirect_to params[:referrer_path] || user_path(@user), :notice => 'Preferencs updated.'
    else
      redirect_to params[:referrer_path] || user_path(@user), :alert => 'Unable to update preferences.'
    end
  end

  def update
    authorize @user
    if @user.update(secure_params)
      redirect_to users_path, :notice => 'User updated.'
    else
      redirect_to users_path, :alert => 'Unable to update user.'
    end
  end

  def destroy
    authorize @user
    @user.destroy
    redirect_to users_path, :notice => 'User deleted.'
  end

  def add_interest
    authorize @user
    person = Person.friendly.find(params[:person])
    @user.add_interest(person)
    redirect_to people_path(search: params[:search], page: params[:page])
  end

  def remove_interest
    authorize @user
    person = Person.friendly.find(params[:person])
    @user.remove_interest(person)
    redirect_to people_path(search: params[:search], page: params[:page])
  end

  private

  def secure_params
    params.require(:user).permit(:role)
  end

  def set_user
    @user = User.friendly.find(params[:id])
  end
end
