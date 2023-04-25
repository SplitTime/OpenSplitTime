# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :spread, :summary, :podium]
  before_action :set_event, except: [:new, :edit, :create, :update, :destroy, :reassign]
  before_action :set_event_group, only: [:new, :create]
  before_action :set_event_group_and_event, only: [:edit, :update, :destroy, :reassign]
  before_action :redirect_to_friendly, only: [:podium, :spread, :summary]
  after_action :verify_authorized, except: [:show, :spread, :summary, :podium]

  MAX_SUMMARY_EFFORTS = 1000
  FINISHERS_ONLY_EXPORT_FORMATS = [:finishers, :itra].freeze

  # GET /events/1
  def show
    redirect_to :spread_event
  end

  # GET /event_groups/1/events/1/new
  def new
    course = params[:course_id].present? ? @event_group.organization.courses.friendly.find(params[:course_id]) : nil
    @event = @event_group.events.new(
      course: course,
      laps_required: 1,
      results_template: ::ResultsTemplate.default
    )
    # Scheduled start time has to be set separately otherwise home_time_zone
    # delegation does not work
    @event.scheduled_start_time_local = @event_group.scheduled_start_time_local || (7.days.from_now.in_time_zone(@event.home_time_zone).midnight + 6.hours)
    authorize @event

    @presenter = ::EventSetupPresenter.new(@event, view_context)
  end

  # GET /event_groups/1/events/1/edit
  def edit
    authorize @event
    @presenter = ::EventSetupPresenter.new(@event, view_context)
  end

  # POST /event_groups/1/events
  def create
    @event = @event_group.events.new
    @event.assign_attributes(permitted_params)
    authorize @event

    if @event.save
      redirect_to setup_course_event_group_event_path(@event_group, @event)
    else
      @presenter = ::EventSetupPresenter.new(@event, view_context)
      render "new", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /event_groups/1/events/1
  def update
    authorize @event

    if @event.update(permitted_params)
      respond_to do |format|
        format.html { redirect_to setup_event_group_path(@event_group) }
        format.turbo_stream do
          presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
          render "update", locals: { presenter: presenter, event: @event }
        end
      end
    else
      @presenter = ::EventSetupPresenter.new(@event, view_context)
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /event_groups/1/events/1
  def destroy
    authorize @event

    @event.destroy
    respond_to do |format|
      format.html { redirect_to setup_event_group_path(@event_group) }
      format.turbo_stream { @presenter = EventGroupSetupPresenter.new(@event_group, view_context) }
    end
  end

  # GET /event_groups/1/events/1/setup_course
  def setup_course
    authorize @event

    @presenter = EventSetupCoursePresenter.new(@event, view_context)
  end

  # GET /event_groups/1/events/1/new_course_gpx
  def new_course_gpx
    authorize @event

    render partial: "events/course_gpx_form", locals: { event: @event }
  end

  # PATCH /event_groups/1/events/1/attach_course_gpx
  def attach_course_gpx
    authorize @event

    @event.course.gpx.attach(params.require(:course).require(:gpx))
    Interactors::SetTrackPoints.perform!(@event.course)

    redirect_to setup_course_event_group_event_path(@event.event_group, @event)
  end

  # DELETE /event_groups/1/events/1/remove_course_gpx
  def remove_course_gpx
    authorize @event

    course = @event.course

    if course.gpx.attached?
      course.gpx.purge
      Interactors::SetTrackPoints.perform!(course)
    end

    redirect_to setup_course_event_group_event_path(@event.event_group, @event)
  end

  # PATCH /event_groups/1/events/1/reassign
  def reassign
    authorize @event

    @event.assign_attributes(params.require(:event).permit(:event_group_id))
    redirect_id = @event.event_group_id || @event.changed_attributes["event_group_id"]

    response = Interactors::UpdateEventAndGrouping.perform!(@event)

    if response.successful?
      respond_to do |format|
        format.html { redirect_to setup_event_group_path(redirect_id) }
        format.turbo_stream do
          redirect_event_group = EventGroup.find(redirect_id)
          presenter = ::EventGroupSetupPresenter.new(redirect_event_group, view_context)
          render turbo_stream: turbo_stream.replace("event_overview_cards", partial: "event_groups/event_overview_cards", locals: { presenter: presenter })
        end
      end
    else
      set_flash_message(response)
      redirect_to setup_event_group_path(redirect_id), status: :unprocessable_entity
    end

  end

  # Special views with results

  # GET /events/1/spread
  def spread
    @presenter = EventSpreadDisplay.new(event: @event, params: prepared_params, current_user: current_user)
    respond_to do |format|
      format.html
      format.csv do
        authorize @event
        csv_stream = render_to_string(partial: "spread", formats: :csv)
        send_data(csv_stream,
                  type: "text/csv",
                  filename: "#{@event.name}-#{@presenter.display_style}-#{Date.today}.csv")
      end
    end
  end

  # GET /events/1/summary
  def summary
    event = Event.where(id: @event.id).includes(:course, :splits, event_group: :organization).references(:course, :splits, event_group: :organization).first
    params[:per_page] ||= MAX_SUMMARY_EFFORTS
    @presenter = SummaryPresenter.new(event: event, params: prepared_params, current_user: current_user)
  end

  # GET /events/1/podium
  def podium
    template = Results::FillEventTemplate.perform(@event)
    @presenter = PodiumPresenter.new(@event, template, prepared_params, current_user)
  end

  # Actions related to the event/effort/split_time relationship

  # PUT /events/1/set_stops
  def set_stops
    authorize @event
    event = Event.where(id: @event.id).includes(efforts: { split_times: :split }).first
    stop_status = params[:stop_status].blank? ? true : params[:stop_status].to_boolean
    response = Interactors::UpdateEffortsStop.perform!(event.efforts, stop_status: stop_status)
    set_flash_message(response)
    redirect_to setup_event_group_path(@event.event_group)
  end

  # This action updates the event scheduled start time and adjusts absolute time on all
  # existing split_times to keep elapsed times consistent.
  #
  # GET /events/1/edit_start_time
  def edit_start_time
    authorize @event
  end

  # PATCH /events/1/update_start_time
  def update_start_time
    authorize @event

    @event.assign_attributes(permitted_params)

    if @event.valid?
      new_start_time = @event.scheduled_start_time_local.to_s
      @event.reload
      response = EventUpdateStartTimeJob.perform_now(@event, new_start_time: new_start_time, current_user: current_user)
      set_flash_message(response)
      redirect_to setup_event_group_path(@event.event_group)
    else
      render :edit_start_time
    end
  end

  # GET /events/1/export
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
        partial = lookup_context.exists?(export_format, :events, true) ? export_format.to_s : "not_found"

        csv_stream = render_to_string(
          partial: partial,
          formats: :csv,
          locals: { current_time: current_time, records: records, options: options }
        )

        send_data(csv_stream, type: "text/csv", filename: filename)
      end
    end
  end

  # GET /events/1/preview_lottery_sync
  def preview_lottery_sync
    authorize @event

    presenter = ::LotterySyncPreviewPresenter.new(@event, view_context)
    render partial: "preview_lottery_sync", locals: { presenter: presenter }
  end

  # GET /events/1/preview_sync
  def preview_sync
    authorize @event

    presenter = ::EventSyncPreviewPresenter.new(@event, view_context, previewer: Interactors::SyncRunsignupParticipants)
    render partial: "preview_sync", locals: { presenter: presenter }
  end

  # POST /events/1/sync_lottery_entrants
  def sync_lottery_entrants
    authorize @event

    response = ::Interactors::SyncLotteryEntrants.perform!(@event)
    set_flash_message(response)
    redirect_to entrants_event_group_path(@event.event_group)
  end

  # POST /events/1/sync_entrants
  def sync_entrants
    authorize @event

    response = ::Interactors::SyncRunsignupParticipants.perform!(@event, current_user)
    set_flash_message(response)
    redirect_to entrants_event_group_path(@event.event_group)
  end

  private

  def reconcile_redirect_path
    "#{event_staging_app_path(@event)}#/entrants"
  end

  def set_event
    @event = policy_scope(Event).friendly.find(params[:id])
  end

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:event_group_id])
  end

  def set_event_group_and_event
    @event_group = ::EventGroup.friendly.find(params[:event_group_id])
    @event = @event_group.events.friendly.find(params[:id])
  end

  def redirect_to_friendly
    redirect_numeric_to_friendly(@event, params[:id])
  end
end
