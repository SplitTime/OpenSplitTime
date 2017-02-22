class Api::V1::LocationsController < ApiController
  before_action :set_location, except: :create

  def show
    authorize @location
    render json: @location
  end

  def create
    location = Location.new(location_params)
    authorize location

    if location.save
      render json: location
    else
      render json: {message: 'location not created', error: "#{location.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @location
    if @location.update(location_params)
      render json: @location
    else
      render json: {message: 'location not updated', error: "#{@location.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @location
    if @location.destroy
      render json: @location
    else
      render json: {message: 'location not destroyed', error: "#{@location.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_location
    @location = Location.find_by(id: params[:id])
    render json: {message: 'location not found'}, status: :not_found unless @location
  end

  def location_params
    params.require(:location).permit(:id, :name, :latitude, :longitude, :elevation, :description)
  end
end