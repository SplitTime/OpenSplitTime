class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @events = Event.all
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
    authorize @event
  end

  def edit
    @event = Event.find(params[:id])
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    authorize @event

    if @event.save
      redirect_to @event
    else
      render 'new'
    end
  end

  def update
    @event = Event.find(params[:id])
    authorize @event

    if @event.update(event_params)
      redirect_to @event
    else
      render 'edit'
    end
  end

  def destroy
    event = Event.find(params[:id])
    authorize event
    event.destroy

    redirect_to events_path
  end

  private

  def event_params
    params.require(:event).permit(:course_id, :race_id, :name, :start_date)
  end

  def query_params
    params.permit(:name)
  end

end
