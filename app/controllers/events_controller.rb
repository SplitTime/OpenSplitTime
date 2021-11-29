class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :spread, :summary, :podium, :series, :place, :analyze]
  before_action :set_event, except: [:new, :create, :series]
  after_action :verify_authorized, except: [:show, :spread, :summary, :podium, :series, :place, :analyze]

  MAX_SUMMARY_EFFORTS = 1000
  FINISHERS_ONLY_EXPORT_FORMATS = [:finishers, :itra].freeze

  def show
    redirect_to :spread_event
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
      redirect_to event_group_path(@event.event_group)
    else
      render 'new'
    end
  end

  def update
    authorize @event

    if @event.update(permitted_params)
      redirect_to event_group_path(@event.event_group, force_settings: true)
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to event_groups_path
  end

  def reassign
    authorize @event
    @event.assign_attributes(params.require(:event).permit(:event_group_id))

    response = Interactors::UpdateEventAndGrouping.perform!(@event)
    set_flash_message(response) unless response.successful?
    redirect_to session.delete(:return_to) || event_group_path(@event.event_group)
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
    @presenter = SummaryPresenter.new(event: event, params: prepared_params, current_user: current_user)
  end

  def podium
    template = Results::FillEventTemplate.perform(@event)
    @presenter = PodiumPresenter.new(@event, template, prepared_params, current_user)
  end

  # Event admin actions

  def delete_all_efforts
    authorize @event
    response = Interactors::BulkDestroyEfforts.perform!(@event.efforts)
    set_flash_message(response) unless response.successful?
    redirect_to case request.referrer
                when nil
                  event_staging_app_path(@event)
                when event_staging_app_url(@event)
                  request.referrer + '#/entrants'
                when edit_event_url(@event)
                  event_group_path(@event.event_group_id)
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

  # This action updates the event scheduled start time and adjusts absolute time on all
  # existing split_times to keep elapsed times consistent.

  def edit_start_time
    authorize @event
  end

  def update_start_time
    authorize @event

    @event.assign_attributes(permitted_params)

    if @event.valid?
      new_start_time = @event.scheduled_start_time_local.to_s
      @event.reload
      response = EventUpdateStartTimeJob.perform_now(@event, new_start_time: new_start_time, current_user: current_user)
      set_flash_message(response)
      redirect_to event_group_path(@event.event_group, force_settings: true)
    else
      render :edit_start_time
    end
  end

  def export
    authorize @event
    params[:per_page] = @event.efforts.size # Get all efforts without pagination
    @presenter = ::EventWithEffortsPresenter.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.csv do
        options = {}
        options[:event_finished] = @presenter.event_finished?

        export_format = params[:export_format].to_sym
        current_time = Time.current.in_time_zone(@event.home_time_zone)
        records = @presenter.ranked_effort_rows
        records = records.select(&:finished?) if export_format.in?(FINISHERS_ONLY_EXPORT_FORMATS)
        filename = "#{@presenter.name}-#{export_format}-#{current_time.iso8601}.csv"

        requested_export_template = "#{export_format}.csv.ruby"
        requested_partial_name = Rails.root.join("app/views/events/_#{requested_export_template}")
        partial = File.exists?(requested_partial_name) ? requested_export_template : "not_found.csv.ruby"
        csv_stream = render_to_string(
          partial: partial,
          locals: {current_time: current_time, records: records, options: options}
        )

        send_data(csv_stream, type: 'text/csv', filename: filename)
      end
    end
  end

  private

  def reconcile_redirect_path
    "#{event_staging_app_path(@event)}#/entrants"
  end

  def set_event
    @event = policy_scope(Event).friendly.find(params[:id])
    redirect_numeric_to_friendly(@event, params[:id])
  end
end
