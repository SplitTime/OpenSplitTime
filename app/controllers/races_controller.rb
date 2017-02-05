class RacesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_race, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @races = Race.where(concealed: false)
                 .paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = races_path
  end

  def show
    params[:view] ||= 'events'
    @race_show = RaceShowView.new(@race, params)
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
    if @race.events.present?
      flash[:danger] = 'An organization cannot be deleted so long as any events are associated with it. ' +
          'Delete the related events individually and then delete the organization.'
      redirect_to race_path(@race)
    else
      @race.destroy
      flash[:success] = 'Organization deleted.'
      session[:return_to] = params[:referrer_path] if params[:referrer_path]
      redirect_to session.delete(:return_to) || races_path
    end
  end

  def stewards
    authorize @race
    if params[:search].present?
      user = User.find_by(email: params[:search])
      if user
        if @race.stewards.include?(user)
          flash[:warning] = 'That user is already a steward of this organization.'
        else
          @race.add_stewardship(user)
        end
        params[:search] = nil
      else
        flash[:warning] = 'User was not located.'
      end
    end
    session[:return_to] = stewards_race_path
  end

  def remove_steward
    authorize @race
    user = User.find(params[:user_id])
    @race.remove_stewardship(user)
    redirect_to stewards_race_path
  end

  private

  def race_params
    params.require(:race).permit(:name, :description, :concealed)
  end

  def query_params
    params.permit(:name)
  end

  def set_race
    @race = Race.find(params[:id])
  end

end