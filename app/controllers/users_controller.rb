# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:update, :destroy]
  before_action :authorize_user, only: [:update, :destroy]
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
        csv_stream = render_to_string(partial: "users", formats: :csv, locals: {users: users})
        send_data(csv_stream, type: "text/csv", filename: "users-#{Date.today}.csv")
      end
    end
  end

  def update
    if @user.update(secure_params)
      redirect_to users_path, notice: "User updated."
    else
      redirect_to users_path, alert: "Unable to update user."
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User deleted."
  end

  private

  def authorize_user
    authorize @user
  end

  def secure_params
    params.require(:user).permit(:role)
  end

  def set_user
    @user = User.friendly.find(params[:id])
    redirect_numeric_to_friendly(@user, params[:id])
  end
end
