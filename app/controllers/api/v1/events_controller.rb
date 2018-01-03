class Api::V1::EventsController < ApiController
  include BackgroundNotifiable
  before_action :set_event, except: [:index, :create]
  before_action :authorize_event, except: [:index, :create]

  # GET /api/v1/events/:id
  def show
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

  # PUT /api/v1/events/:id
  def update
    if @event.update(permitted_params)
      render json: @event
    else
      render json: {errors: ['event not updated'], detail: "#{@event.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:id
  def destroy
    if @event.destroy
      render json: @event
    else
      render json: {errors: ['event not destroyed'], detail: "#{@event.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  # GET /api/v1/events/:id/spread
  def spread
    params[:display_style] ||= 'absolute'
    presenter = EventSpreadDisplay.new(event: @event, params: prepared_params)
    spread_display = Rails.cache.fetch("#{presenter.cache_key}/json", expires_in: 1.minute) do
      ActiveModelSerializers::Adapter.create(EventSpreadSerializer.new(presenter), adapter: :json_api, include: :effort_times_rows).to_json
    end
    render json: spread_display
  end

  def import
    if params[:file].is_a?(ActionDispatch::Http::UploadedFile)
      params[:data] = params[:file]
    elsif params[:file]
      params[:data] = File.read(params[:file])
    end

    strict = params[:load_records] != 'single'
    unique_key = params[:unique_key].present? ? (params[:unique_key] + ['event_id']).uniq : nil
    importer = ETL::Importer.new(params[:data],
                                 params[:data_format]&.to_sym,
                                 event: @event,
                                 current_user_id: current_user.id,
                                 strict: strict,
                                 unique_key: unique_key)
    importer.import

    if strict
      if importer.errors.present? || importer.invalid_records.present?
        render json: {errors: importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }},
               status: :unprocessable_entity
      else
        render json: importer.saved_records, status: :created
      end
    else
      render json: {saved_records: importer.saved_records.map { |record| ActiveModel::SerializableResource.new(record) },
                    destroyed_records: importer.destroyed_records.map { |record| ActiveModel::SerializableResource.new(record) },
                    errors: importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }},
             status: importer.saved_records.present? ? :created : :unprocessable_entity
    end

    efforts = importer.saved_records.select { |record| record.is_a?(Effort) }
    if efforts.present?
      EffortsAutoReconcileJob.perform_later(@event, current_user: User.current)
    end

    split_times = importer.saved_records.select { |record| record.is_a?(SplitTime) }
    if split_times.present?
      updated_efforts = @event.efforts.where(id: split_times.map(&:effort_id).uniq).includes(split_times: :split)
      Interactors::UpdateEffortsStatus.perform!(updated_efforts)

      if @event.available_live?
        notifier = BulkFollowerNotifier.new(split_times, multi_lap: @event.multiple_laps?)
        notifier.notify
      end
    end

    live_times = importer.saved_records.select { |record| record.is_a?(LiveTime) }
    if live_times.present? && @event.available_live
      LiveTimeSplitTimeCreator.create(event: @event, live_times: live_times) if @event.auto_live_times?
      report_live_times_available(@event)
    end
  end

  def trigger_live_times_push
    report_live_times_available(@event)
    render json: {message: "Live times push notification sent for #{@event.name}"}
  end

  # This legacy endpoint requires only an event_id, which is passed via the URL as params[:id]
  # It returns a json containing eventId, eventName, and detailed split info
  # for all splits associated with the event.
  #
  # This endpoint should be replaced by EventsController#show
  # and live_entry.js should be updated to parse the jsonapi response.

  #GET /api/v1/events/:id/event_data
  def event_data
    if @event.available_live
      render partial: 'live/events/event_data.json.ruby'
    else
      render json: live_entry_unavailable, status: :forbidden
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

    if @event.available_live
      reporter = LiveDataEntryReporter.new(event: @event, params: params)
      render json: reporter.full_report
    else
      render json: live_entry_unavailable, status: :forbidden
    end
  end

  def set_times_data

    # Each time_row should include splitId, lap, bibNumber, timeIn (military), timeOut (military),
    # pacerIn (boolean), pacerOut (boolean), and droppedHere (boolean). This action ingests time_rows, converts and
    # verifies data, creates new split_times for valid time_rows, and returns invalid time_rows intact.

    if @event.available_live
      importer = LiveTimeRowImporter.new(event: @event, time_rows: params[:time_rows])
      importer.import
      returned_rows = importer.returned_rows

      if importer.errors.present?
        render json: {errors: importer.errors}, status: :unprocessable_entity
      else
        render json: returned_rows
      end
    else
      render json: live_entry_unavailable, status: :forbidden
    end
  end

  def post_file_effort_data

    # Params should be an unaltered CSV file and a splitId.
    # This endpoint interprets and verifies rows from the file and returns
    # return_rows containing all data necessary to populate the local data workspace.

    if @event.available_live
      returned_rows = LiveFileTransformer.returned_rows(event: @event, file: params[:file], split_id: params[:split_id])
      render json: {returnedRows: returned_rows}, status: :created
    else
      render json: live_entry_unavailable, status: :forbidden
    end
  end

  def pull_live_time_rows

    # This endpoint searches for un-pulled live_times related to the event, selects a batch,
    # marks them as pulled, combines them into live_time_rows, and returns them
    # to the live entry page.

    # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
    # If params[:force_pull] == true, live_times without a matching split_time will be pulled
    # even if they show as already having been pulled.

    if @event.available_live
      force_pull = params[:force_pull]&.to_boolean
      live_times_default_limit = 50
      live_times_limit = (params[:page] && params[:page][:size]) || live_times_default_limit

      scoped_live_times = force_pull ? @event.live_times.unmatched : @event.live_times.unconsidered
      live_times = scoped_live_times.order(:split_id, :bib_number, :bitkey).limit(live_times_limit)

      live_time_rows = LiveTimeRowConverter.convert(event: @event, live_times: live_times)

      live_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
      report_live_times_available(@event)
      render json: {returnedRows: live_time_rows}, status: :ok
    else
      render json: live_entry_unavailable, status: :forbidden
    end
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end

  def authorize_event
    authorize @event
  end

  def live_entry_unavailable
    {reportText: "Live entry for #{@event.name} is currently unavailable. " +
        'Please enable live entry access through the event stage/admin page.'}
  end
end
