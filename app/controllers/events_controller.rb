class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :spread, :podium, :series, :place, :analyze, :drop_list]
  before_action :set_event, except: [:index, :new, :create, :series]
  after_action :verify_authorized, except: [:index, :show, :spread, :podium, :series, :place, :analyze, :drop_list]

  def index
    @events = policy_class::Scope.new(current_user, controller_class).viewable
                  .select_with_params(params[:search])
                  .order(start_time: :desc)
                  .paginate(page: params[:page], per_page: 25)
    @presenter = EventsCollectionPresenter.new(@events, params, current_user)
    session[:return_to] = events_path
  end

  def show
    @event_display = EventEffortsDisplay.new(event: @event, params: prepared_params)
    render 'show'
  end

  def new
    if params[:course_id]
      @event = Event.new(course_id: params[:course_id], laps_required: 1)
      @course = Course.friendly.find(params[:course_id])
    else
      @event = Event.new(laps_required: 1)
    end
    authorize @event
  end

  def edit
    authorize @event
  end

  def create
    @event = Event.new(permitted_params)
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
    @event.assign_attributes(permitted_params)
    response = Interactors::UpdateEventAndGrouping.perform!(@event)

    if response.successful?
      case params[:button]
      when 'join_leave'
        redirect_to request.referrer
      else
        set_flash_message(response)
        redirect_to session.delete(:return_to) || stage_event_path(@event)
      end
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to event_groups_path
  end

  # Special views with results

  def spread
    @spread_display = EventSpreadDisplay.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.html
      format.csv do
        authorize @event
        csv_stream = render_to_string(partial: 'spread.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@event.name}-#{@spread_display.display_style}-#{Date.today}.csv")
      end
    end
  end

  def podium
    template = Results::FillTemplate.perform(event: @event, template_name: @event.podium_template)
    @presenter = PodiumPresenter.new(@event, template)
  end

  def series
    events = Event.find(params[:event_ids])
    @presenter = EventSeriesPresenter.new(events, prepared_params)
  rescue ActiveRecord::RecordNotFound => exception
    flash[:danger] = "#{exception}"
    redirect_to events_path
  end

  # Event staging actions

  def stage
    authorize @event
    @event = Event.where(id: @event.id).includes(:course).includes(:splits).includes(:efforts).includes(event_group: :events).first
    @event_stage = EventStageDisplay.new(event: @event, params: prepared_params)
    params[:view] ||= 'efforts'
    session[:return_to] = stage_event_path(@event)
  end

  def reconcile
    authorize @event
    @unreconciled_batch = @event.unreconciled_efforts.order(:last_name).limit(20)
    if @unreconciled_batch.empty?
      flash[:success] = 'All efforts have been reconciled'
      redirect_to request.referrer.include?('event_staging') ? "#{event_staging_app_path(@event)}#/entrants" : stage_event_path(@event)
    else
      @unreconciled_batch.each { |effort| effort.suggest_close_match }
    end
  end

  def associate_people
    authorize @event
    id_hash = params[:ids].to_unsafe_h
    response = Interactors::AssignPeopleToEfforts.perform!(id_hash)
    set_flash_message(response)
    redirect_to reconcile_event_path(@event)
  end

  def create_people
    authorize @event
    response = Interactors::CreatePeopleFromEfforts.perform!(params[:effort_ids])
    set_flash_message(response)
    redirect_to reconcile_event_path(@event)
  end

  def delete_all_efforts
    authorize @event
    response = Interactors::BulkDeleteEfforts.perform!(@event.efforts)
    set_flash_message(response)
    redirect_to stage_event_path(@event)
  end

  # Actions related to the event/effort/split_time relationship

  def set_data_status
    authorize @event
    event = Event.where(id: @event.id).includes(efforts: {split_times: :split}).first
    response = Interactors::UpdateEffortsStatus.perform!(event.efforts)
    set_flash_message(response)
    redirect_to stage_event_path(@event)
  end

  def set_stops
    authorize @event
    event = Event.where(id: @event.id).includes(efforts: {split_times: :split}).first
    stop_status = params[:stop_status].blank? ? true : params[:stop_status].to_boolean
    response = Interactors::UpdateEffortsStop.perform!(event.efforts, stop_status: stop_status)
    set_flash_message(response)
    redirect_to stage_event_path(@event)
  end

  def update_all_efforts
    authorize @event
    attributes = params.require(:efforts).permit(:checked_in).to_hash
    @event.efforts.update_all(attributes)

    redirect_to stage_event_path(@event)
  end

  # This action updates the event start_time and adjusts time_from_start on all
  # existing non-start split_times to keep absolute time consistent.

  def edit_start_time
    authorize @event
  end

  def update_start_time
    authorize @event
    background_channel = "progress_#{session.id}"
    temp_event = Event.new(home_time_zone: @event.home_time_zone, start_time_in_home_zone: params[:event][:start_time_in_home_zone])
    new_start_time = temp_event.start_time.to_s

    EventUpdateStartTimeJob.perform_later(@event, new_start_time: new_start_time,
                                          background_channel: background_channel, current_user: User.current)
    redirect_to stage_event_path(@event)
  end

  def drop_list
    @event_dropped_display = EventDroppedDisplay.new(event: @event, params: prepared_params)
    session[:return_to] = event_path(@event)
  end

  def export_to_ultrasignup
    authorize @event
    params[:per_page] = @event.efforts.size # Get all efforts without pagination
    @event_display = EventEffortsDisplay.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.html { redirect_to stage_event_path(@event) }
      format.csv do
        csv_stream = render_to_string(partial: 'ultrasignup.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@event.name}-for-ultrasignup-#{Date.today}.csv")
      end
    end
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
    redirect_numeric_to_friendly(@event, params[:id])
  end
end
