class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:import_splits, :import_efforts, :show, :edit,
                                   :update, :destroy, :splits, :associate_split]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @events = Event.all
  end

  def import_splits
    authorize @event
    if Importer.split_import(params[:file], @event)
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No split data detected"
    end

    redirect_to event_path(@event)
  end

  def import_efforts
    authorize @event
    if Importer.effort_import(params[:file], @event)
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No effort data detected"
    end

    redirect_to event_path(@event)
  end

  def show
    @associated_splits = @event.splits
  end

  def new
    @event = Event.new
    authorize @event
  end

  def edit
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
    authorize @event

    if @event.update(event_params)
      redirect_to @event
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to events_path
  end

  def splits
    authorize @event
    @associated_splits = @event.splits
                             .sort_by { |x| [x.distance_from_start, x.sub_order] }
    @other_splits = (@event.course.splits - @associated_splits)
                        .sort_by { |x| [x.distance_from_start, x.sub_order] }
  end

  def associate_split
    authorize @event
    @event_split = EventSplit.new(event_id: @event.id, split_id: params[:split_id])

    if @event_split.save
      redirect_to splits_event_url(id: @event.id)
    else
      redirect_to splits_event_url(id: @project.id),
                  error: "Split was not associated with event"
    end
  end

  private

  def event_params
    params.require(:event).permit(:course_id, :race_id, :name, :start_date, :first_start_time)
  end

  def query_params
    params.permit(:name)
  end

  def set_event
    @event = Event.find(params[:id])
  end

end
