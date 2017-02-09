class Api::V1::LocationsController < ApiController
  before_action :set_location

  def show
    authorize @location
    render json: @location
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end
end