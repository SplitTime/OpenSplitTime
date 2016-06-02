class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :spread]
  before_action :set_event, except: [:index, :show, :new, :create, :spread]
  after_action :verify_authorized, except: [:index, :show, :spread]

  def index
    @events = Event.select("events.*, COUNT(efforts.id) as effort_count")
                  .joins("LEFT OUTER JOIN efforts ON (efforts.event_id = events.id)")
                  .group("events.id")
                  .order(start_time: :desc)
                  .paginate(page: params[:page], per_page: 25)
    session[:return_to] = events_path
  end

  def show
    event = Event.find(params[:id])
    @event_display = EventEffortsDisplay.new(event, params)
    session[:return_to] = event_path(event)
  end

  def new
    if params[:course_id]
      @event = Event.new(course_id: params[:course_id])
      @course = Course.find(params[:course_id])
    else
      @event = Event.new
    end
    authorize @event
  end

  def edit
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    authorize @event

    if @event.save
      @event.set_all_course_splits
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


# Event staging actions

  def stage
    authorize @event
    @associated_splits = @event.splits.ordered
    session[:return_to] = stage_event_path(@event)
  end

  def reconcile
    authorize @event
    @unreconciled_batch = @event.unreconciled_efforts.order(:last_name).limit(20)
    if @unreconciled_batch.count < 1
      flash[:success] = "All efforts reconciled for #{@event.name}"
      redirect_to stage_event_path(@event)
    else
      @unreconciled_batch.each { |effort| effort.suggest_close_match }
    end
  end

  def create_participants
    authorize @event
    EventReconcileService.create_participants_from_efforts(params[:effort_ids])
    redirect_to reconcile_event_path(@event)
  end

  def delete_all_efforts
    authorize @event
    @event.efforts.destroy_all
    flash[:warning] = "All efforts deleted for #{@event.name}"
    redirect_to stage_event_path(@event)
  end

# Import actions

  def import_splits
    authorize @event
    @importer = Importer.new(params[:file], @event, current_user.id)
    if @importer.split_import
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No split data detected"
    end

    redirect_to stage_event_path(@event)
  end

  def import_efforts
    authorize @event
    @importer = Importer.new(params[:file], @event, current_user.id)
    if @importer.effort_import
      flash[:success] = "Import successful. #{@importer.effort_import_report}"
    else
      flash[:danger] = "Could not complete the import. #{@importer.errors.messages[:importer].first}."
    end

    redirect_to stage_event_path(@event, errors: @importer.errors)
  end

  def spread
    event = Event.find(params[:id])
    @spread_display = EventSpreadDisplay.new(event, params)
    session[:return_to] = spread_event_path(event)
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
    authorize @event
    @event.splits.delete(Split.intermediate)
    redirect_to splits_event_path(@event)
  end

  def set_data_status
    authorize @event
    DataStatusService.set_data_status(@event.efforts)
    redirect_to event_path(@event)
  end

  private

  def event_params
    params.require(:event).permit(:course_id, :race_id, :name, :start_time)
  end

  def query_params
    params.permit(:name)
  end

  def set_event
    @event = Event.find(params[:id])
  end

end
