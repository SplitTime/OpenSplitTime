class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :spread, :summary, :podium, :series, :place, :analyze]
  before_action :set_event, except: [:new, :create, :series]
  after_action :verify_authorized, except: [:show, :spread, :summary, :podium, :series, :place, :analyze]

  MAX_SUMMARY_EFFORTS = 1000

  def show
    event = Event.where(id: @event.id).includes(:course, :splits, event_group: :organization).references(:course, :splits, event_group: :organization).first
    @presenter = EventWithEffortsPresenter.new(event: event, params: prepared_params, current_user: current_user)
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
      redirect_to event_group_path(@event.event_group)
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
        redirect_to event_group_path(@event.event_group, force_settings: true)
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
    @presenter = EventSpreadDisplay.new(event: @event, params: prepared_params, current_user: current_user)
    respond_to do |format|
      format.html
      format.csv do
        authorize @event
        csv_stream = render_to_string(partial: 'spread.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@event.name}-#{@presenter.display_style}-#{Date.today}.csv")
      end
    end
  end

  def summary
    event = Event.where(id: @event.id).includes(:course, :splits, event_group: :organization).references(:course, :splits, event_group: :organization).first
    params[:per_page] ||= MAX_SUMMARY_EFFORTS
    @presenter = EventWithEffortsPresenter.new(event: event, params: prepared_params, current_user: current_user)
  end

  def podium
    template = Results::FillTemplate.perform(event: @event, template_name: @event.podium_template)
    @presenter = PodiumPresenter.new(@event, template, current_user)
  end

  def series
    events = Event.find(params[:event_ids])
    @presenter = EventSeriesPresenter.new(events, prepared_params)
  rescue ActiveRecord::RecordNotFound => exception
    flash[:danger] = "#{exception}"
    redirect_to event_groups_path
  end

  # Event admin actions

  def reconcile
    authorize @event

    event = Event.where(id: @event.id).includes(efforts: :person).first
    @presenter = EventReconcilePresenter.new(event: event, params: prepared_params, current_user: current_user)

    if @presenter.event_efforts.empty?
      flash[:success] = 'No efforts have been added to this event'
      redirect_to reconcile_redirect_path
    elsif @presenter.unreconciled_batch.empty?
      flash[:success] = 'All efforts have been reconciled'
      redirect_to reconcile_redirect_path
    end
  end

  def auto_reconcile
    authorize @event

    EffortsAutoReconcileJob.perform_later(@event, current_user: current_user)
    flash[:success] = 'Automatic reconcile has started. Please return to reconcile after a minute or so.'
    redirect_to reconcile_redirect_path
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
    set_flash_message(response) unless response.successful?
    redirect_to case request.referrer
                when nil
                  event_staging_app_path(@event)
                when event_staging_app_url(@event)
                  request.referrer + '#/entrants'
                else
                  request.referrer
                end
  end

  # Actions related to the event/effort/split_time relationship

  def set_stops
    authorize @event
    event = Event.where(id: @event.id).includes(efforts: {split_times: :split}).first
    stop_status = params[:stop_status].blank? ? true : params[:stop_status].to_boolean
    response = Interactors::UpdateEffortsStop.perform!(event.efforts, stop_status: stop_status)
    set_flash_message(response)
    redirect_to event_group_path(@event.event_group, force_settings: true)
  end

  # This action updates the event start_time and adjusts time_from_start on all
  # existing non-start split_times to keep absolute time consistent.

  def edit_start_time
    authorize @event
  end

  def update_start_time
    authorize @event
    background_channel = "progress_#{session.id}"
    temp_event = Event.new(home_time_zone: @event.home_time_zone, start_time_local: params[:event][:start_time_local])
    new_start_time = temp_event.start_time.to_s

    EventUpdateStartTimeJob.perform_later(@event, new_start_time: new_start_time,
                                          background_channel: background_channel, current_user: User.current)
    redirect_to event_group_path(@event.event_group, force_settings: true)
  end

  def export_finishers
    authorize @event
    params[:per_page] = @event.efforts.size # Get all efforts without pagination
    @presenter = EventWithEffortsPresenter.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.csv do
        options = {}
        export_format = :finishers
        current_time = Time.current.in_time_zone(@event.home_time_zone)
        records = @presenter.ranked_effort_rows.select(&:finished?)
        csv_stream = render_to_string(partial: 'finishers.csv.ruby', locals: {current_time: current_time, records: records, options: options})
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@presenter.name}-#{export_format}-#{current_time.strftime('%Y-%m-%d-%H-%M-%S')}.csv")
      end
    end
  end

  def export_to_ultrasignup
    authorize @event
    params[:per_page] = @event.efforts.size # Get all efforts without pagination
    @presenter = EventWithEffortsPresenter.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.csv do
        options = {}
        export_format = :ultrasignup
        current_time = Time.current.in_time_zone(@event.home_time_zone)
        records = @presenter.ranked_effort_rows
        options[:event_finished] = @presenter.event_finished?
        csv_stream = render_to_string(partial: 'ultrasignup.csv.ruby', locals: {current_time: current_time, records: records, options: options})
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@presenter.name}-#{export_format}-#{current_time.strftime('%Y-%m-%d-%H-%M-%S')}.csv")
      end
    end
  end

  private

  def reconcile_redirect_path
    "#{event_staging_app_path(@event)}#/entrants"
  end

  def set_event
    @event = Event.friendly.find(params[:id])
    redirect_numeric_to_friendly(@event, params[:id])
  end
end
