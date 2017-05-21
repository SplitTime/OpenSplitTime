class Api::V1::UsersController < ApiController
  before_action :set_resource, except: [:index, :create, :current]

  def current
    authorize User
    render json: current_user
  end

  private
end
