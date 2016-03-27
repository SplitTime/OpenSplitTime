class LocationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_location, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @locations = Location.all.order(:longitude)
  end

  def show
  end

  def new
    @location = Location.new
    @split = Split.find(params[:split_id]) unless params[:split_id].nil?
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
      conform_split_locations_to(params[:split_id]) unless params[:split_id].nil?
      redirect_to session.delete(:return_to) || @location
    else
      render 'new'
    end
  end

  def update
    authorize @location

    if @location.update(location_params)
      redirect_to session.delete(:return_to) || @location
    else
      render 'edit'
    end
  end

  def destroy
    authorize @location
    @location.destroy

    redirect_to session.delete(:return_to) || locations_path
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
