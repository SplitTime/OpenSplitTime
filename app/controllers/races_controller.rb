class RacesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @races = Race.all
  end

  def show
    @race = Race.find(params[:id])
  end

  def new
    @race = Race.new
    authorize @race
  end

  def edit
    @race = Race.find(params[:id])
    authorize @race
  end

  def create
    @race = Race.new(race_params)
    authorize @race

    if @race.save
      redirect_to @race
    else
      render 'new'
    end
  end

  def update
    @race = Race.find(params[:id])
    authorize @race

    if @race.update(race_params)
      redirect_to @race
    else
      render 'edit'
    end
  end

  def destroy
    race = Race.find(params[:id])
    authorize race
    race.destroy

    redirect_to races_path
  end

  private

  def race_params
    params.require(:race).permit(:name, :description)
  end

  def query_params
    params.permit(:name)
  end

end