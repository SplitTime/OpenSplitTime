class Api::V1::EventsController < ApiController
  before_action :set_event, except: :create

  # GET /api/v1/events/:staging_id
  def show
    authorize @event
    render json: @event, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  # POST /api/v1/events
  def create
    event = Event.new(permitted_params)
    authorize event

    if event.save
      event.reload
      render json: event, status: :created
    else
      render json: {errors: ['event not created'], detail: "#{event.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/events/:staging_id
  def update
    authorize @event
    if @event.update(permitted_params)
      render json: @event
    else
      render json: {errors: ['event not updated'], detail: "#{@event.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:staging_id
  def destroy
    authorize @event
    if @event.destroy
      render json: @event
    else
      render json: {errors: ['event not destroyed'], detail: "#{@event.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  # GET /api/v1/events/:staging_id/spread
  def spread
    authorize @event
    params[:display_style] ||= 'absolute'
    spread_display = EventSpreadDisplay.new(event: @event, params: prepared_params)
    render json: spread_display, serializer: EventSpreadSerializer, include: 'effort_times_rows'
  end

  # Send 'with_times' => 'false' to ignore split_time data
  # Send 'time_format' => 'elapsed' or 'military' depending on time data format
  # Send 'with_status' => 'false' to skip setting data status for imported split_times

  # POST /api/v1/events/:staging_id/import_efforts
  def import_efforts
    authorize @event
    file_url = FileStore.public_upload('imports', params[:file], current_user.id)
    if file_url
      if Rails.env.production?
        ImportEffortsJob.perform_later(file_url, @event, current_user.id, params.slice(:time_format, :with_times, :with_status))
        render json: {message: 'Import in progress.'}
      else
        ImportEffortsJob.perform_now(file_url, @event, current_user.id, params.slice(:time_format, :with_times, :with_status))
        render json: {message: 'Import complete.'}
      end
    else
      render json: {errors: ['Import file too large.']}, status: :bad_request
    end
  end

  def import
    authorize @event
    body = request.body
    format = params[:data_format].to_sym
    importer = DataImport::Importer.new(body, format, event: @event)
    importer.import
    if importer.errors.present? || importer.invalid_records.present?
      render json: {errors: importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }}, status: :unprocessable_entity
    else
      render json: {message: 'Import complete'}, status: :created
    end
  end

  # This legacy endpoint requires only an event_id, which is passed via the URL as params[:id]
  # It returns a json containing eventId, eventName, and detailed split info
  # for all splits associated with the event.
  #
  # This endpoint should be replaced by EventsController#show
  # and live_entry.js should be updated to parse the jsonapi response.

  #GET /api/v1/events/:staging_id/event_data
  def event_data

    authorize @event
    if @event.available_live
      render partial: 'live/events/event_data.json.ruby'
    else
      render partial: 'live/events/live_entry_unavailable.json.ruby'
    end
  end

  # This endpoint is called on any of the following conditions:
  # - split selector is changed
  # - bib # field is changed
  # - time in or time out field is changed

  def live_effort_data

    # Params should include at least splitId and bibNumber. Params may also include timeIn and timeOut.
    # This endpoint returns as many of the following as it can determine:
    # { effortId (integer), name (string), reportedText (string), dropped (bool), finished (bool),
    # timeFromLastReported ("hh:mm"), timeInAid ("mm minutes"), timeInExists (bool), timeOutExists (bool),
    # timeInStatus ('good', 'questionable', 'bad'), timeOutStatus ('good', 'questionable', 'bad') }

    authorize @event
    if @event.available_live
      @live_data_entry_reporter = LiveDataEntryReporter.new(event: @event, params: params)
      render partial: 'live/events/live_effort_data.json.ruby'
    else
      render partial: 'live/events/live_entry_unavailable.json.ruby'
    end
  end

  def set_times_data

    # Each time_row should include splitId, lap, bibNumber, timeIn (military), timeOut (military),
    # pacerIn (boolean), pacerOut (boolean), and droppedHere (boolean). This action ingests time_rows, converts and
    # verifies data, creates new split_times for valid time_rows, and returns invalid time_rows intact.

    authorize @event
    if @event.available_live
      @returned_rows = LiveTimeRowImporter.import(event: @event, time_rows: params[:time_rows])
      render partial: 'live/events/set_times_data_report.json.ruby'
    else
      render partial: 'live/events/live_entry_unavailable.json.ruby'
    end
  end

  def post_file_effort_data

    # Params should be an unaltered CSV file and a splitId.
    # This endpoint interprets and verifies rows from the file and returns
    # return_rows containing all data necessary to populate the local data workspace.

    authorize @event
    if @event.available_live
      @returned_rows = LiveFileTransformer.returned_rows(event: @event, file: params[:file], split_id: params[:split_id])
      render partial: 'live/events/file_effort_data_report.json.ruby'
    else
      render partial: 'live/events/live_entry_unavailable.json.ruby'
    end
  end

  private

  def set_event
    @event = params[:staging_id].uuid? ?
                 Event.find_by!(staging_id: params[:staging_id]) :
                 Event.friendly.find(params[:staging_id])
  end
end
