class LocationsController < ApplicationController

  def index
    @locations = Location.all
  end

  def show
    @location = Location.find(params[:id])
  end

  def new
    @location = Location.new
  end

  def edit
    @location = Location.find(params[:id])
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      redirect_to @location
    else
      render 'new'
    end
  end

  def update
    @location = Location.find(params[:id])

    if @location.update(location_params)
      redirect_to @location
    else
      render 'edit'
    end
  end

  def destroy
    @location = Location.find(params[:id])
    @location.destroy

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
