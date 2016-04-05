class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @events = Event.paginate(page: params[:page], per_page: 25).order(first_start_time: :desc)
    session[:return_to] = events_path
  end

  def show
    if @event.course
      @efforts = @event.race_sorted_efforts.includes(:split_times).paginate(page: params[:page], per_page: 25)
      session[:return_to] = event_path(@event)
    else
      flash[:danger] = "Event must have a course"
      render 'edit'
      session[:return_to] = event_path(@event)
    end
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
      redirect_to stage_event_path(@event)
    else
      render 'new'
    end
  end

  def update
    authorize @event

    if @event.update(event_params)
      redirect_to session.delete(:return_to) || @event
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event
    @event.destroy

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || events_path
  end


  # All actions below are related to event staging

  def stage
    authorize @event
    @associated_splits = @event.splits.ordered
    session[:return_to] = stage_event_path(@event)
  end


  # Import actions

  def import_splits
    authorize @event
    if Importer.split_import(params[:file], @event)
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No split data detected"
    end

    redirect_to stage_event_path(@event)
  end

  def import_efforts
    authorize @event
    if Importer.effort_import(params[:file], @event, current_user.id)
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No effort data detected"
    end

    redirect_to stage_event_path(@event)
  end


  # Actions related to the event/split relationship

  def splits
    authorize @event
    @other_splits = @event.course.splits.ordered - @event.splits
  end

  def associate_splits
    authorize @event
    if params[:split_ids].nil?
      redirect_to :back
    else
      params[:split_ids].each do |split_id|
        @event.splits << Split.find(split_id)
      end
      redirect_to splits_event_url(id: @event.id)
    end
  end

  def remove_split
    authorize @event
    @event.splits.delete(params[:split_id])
    redirect_to splits_event_path(@event)
  end

  def remove_all_splits
    @event = Event.find(params[:id])
    authorize @event
    @event.splits.delete_all
    redirect_to splits_event_path(@event)
  end


  # Action for reconciling event.efforts data with existing participants

  def reconcile
    authorize @event
    @unreconciled_efforts = @event.unreconciled_efforts.order(:last_name)
  end


  private

  def event_params
    params.require(:event).permit(:course_id, :race_id, :name, :first_start_time)
  end

  def query_params
    params.permit(:name)
  end

  def set_event
    @event = Event.find(params[:id])
  end

end
