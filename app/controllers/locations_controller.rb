class LocationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @locations = Location.all
  end

  def show
    @location = Location.find(params[:id])
  end

  def new
    @location = Location.new
    authorize @location
  end

  def edit
    @location = Location.find(params[:id])
    authorize @location
  end

  def create
    @location = Location.new(location_params)
    authorize @location

    if @location.save
      redirect_to @location
    else
      render 'new'
    end
  end

  def update
    @location = Location.find(params[:id])
    authorize @location

    if @location.update(location_params)
      redirect_to @location
    else
      render 'edit'
    end
  end

  def destroy
    location = Location.find(params[:id])
    authorize location
    location.destroy

    redirect_to locations_path
  end

  private

  def location_params
    params.require(:location).permit(:name, :elevation, :latitude, :longitude)
  end

  def query_params
    params.permit(:name)
  end

end
