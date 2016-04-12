class RacesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_race, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @races = Race.paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = races_path
  end

  def show
    @race_events = @race.events
    session[:return_to] = race_path(@race)
  end

  def new
    @race = Race.new
    authorize @race
  end

  def edit
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
    authorize @race

    if @race.update(race_params)
      redirect_to @race
    else
      render 'edit'
    end
  end

  def destroy
    authorize @race
    @race.destroy

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || races_path
  end

  private

  def race_params
    params.require(:race).permit(:name, :description)
  end

  def query_params
    params.permit(:name)
  end

  def set_race
    @race = Race.find(params[:id])
  end

end