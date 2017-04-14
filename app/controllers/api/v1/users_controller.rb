class Api::V1::UsersController < ApiController
  before_action :set_user, except: [:create, :current]

  def show
    authorize @user
    render json: @user, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    user = User.new(permitted_params)
    authorize user

    if user.save
      render json: user, status: :created
    else
      render json: {message: 'user not created', error: "#{user.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @user
    if @user.update(permitted_params)
      render json: @user
    else
      render json: {message: 'user not updated', error: "#{@user.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @user
    if @user.destroy
      render json: @user
    else
      render json: {message: 'user not destroyed', error: "#{@user.errors.full_messages}"}, status: :bad_request
    end
  end

  def current
    authorize User
    render json: current_user
  end

  private

  def set_user
    @user = User.friendly.find(params[:id])
  end
end
