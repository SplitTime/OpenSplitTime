class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :spread, :drop_list]
  before_action :set_event, except: [:index, :show, :new, :create, :spread]
  after_action :verify_authorized, except: [:index, :show, :spread, :drop_list]

  def index
    @events = Event.select_with_params(params[:search])
                  .paginate(page: params[:page], per_page: 25)
    session[:return_to] = events_path
  end

  def show
    event = Event.find(params[:id])
    if event.started?
      @event_display = EventEffortsDisplay.new(event, params)
      session[:return_to] = event_path(event)
      render 'show'
    else
      @event_preview = EventPreviewDisplay.new(event, params)
      session[:return_to] = event_path(event)
      render 'preview'
    end
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
    @event_stage = EventStageDisplay.new(@event, params)
    params[:view] ||= 'efforts'
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
    @importer = SplitImporter.new(params[:file], @event, current_user.id)
    if @importer.split_import
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No split data detected"
    end

    redirect_to stage_event_path(@event)
  end

  def import_efforts
    authorize @event
    @importer = EffortImporter.new(params[:file], @event, current_user.id)
    if @importer.effort_import
      flash[:success] = "Import successful. #{@importer.effort_import_report}"
      redirect_to reconcile_event_path(@event)
    else
      flash[:danger] = "Could not complete the import. #{@importer.errors.messages[:effort_importer].first}."
      redirect_to stage_event_path(@event, errors: @importer.errors)
    end
  end

  def import_efforts_without_times
    authorize @event
    @importer = EffortImporter.new(params[:file], @event, current_user.id)
    if @importer.effort_import_without_times
      flash[:success] = "Import successful. #{@importer.effort_import_report}"
      redirect_to reconcile_event_path(@event)
    else
      flash[:danger] = "Could not complete the import. #{@importer.errors.messages[:effort_importer].first}."
      redirect_to stage_event_path(@event, errors: @importer.errors)
    end
  end

  def spread
    event = Event.find(params[:id])
    params[:style] ||= event.available_live ? 'ampm' : 'elapsed'
    params[:sort] ||= 'place'
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
    report = DataStatusService.set_data_status(@event.efforts)
    flash[:warning] = report if report
    redirect_to stage_event_path(@event)
  end

  def start_all_efforts
    authorize @event
    report = BulkUpdateService.start_all_efforts(@event, @current_user.id)
    flash[:warning] = report if report
    redirect_to stage_event_path(@event)
  end

# Enable/disable availability for live views

  def live_enable
    authorize @event
    @event.update(available_live: true)
    redirect_to stage_event_path(@event)
  end

  def live_disable
    authorize @event
    @event.update(available_live: false)
    redirect_to stage_event_path(@event)
  end

  def add_beacon
    authorize @event
    update_beacon_url(params[:value])
    respond_to do |format|
      format.html { redirect_to stage_event_path(@event) }
      format.js { render inline: "location.reload();" }
    end
  end

  def drop_list
    @event_dropped_display = EventDroppedDisplay.new(@event)
    session[:return_to] = event_path(@event)
  end

  private

  def event_params
    params.require(:event).permit(:course_id, :race_id, :name, :start_time, :demo)
  end

  def query_params
    params.permit(:name)
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def update_beacon_url(url)
    @event.update(beacon_url: url)
  end

end
