class LocationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_location, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @locations = Location.all
  end

  def show
  end

  def new
    @location = Location.new
    authorize @location
  end

  def edit
    session[:return_to] ||= request.referer
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
    authorize @location

    if @location.update(location_params)
      redirect_to session.delete(:return_to)
    else
      render 'edit'
    end
  end

  def destroy
    authorize @location
    @location.destroy

    redirect_to locations_path
  end

  private

  def location_params
    params.require(:location).permit(:name, :description, :elevation, :latitude, :longitude)
  end

  def query_params
    params.permit(:name)
  end

  def set_location
    @location = Location.find(params[:id])
  end

end
