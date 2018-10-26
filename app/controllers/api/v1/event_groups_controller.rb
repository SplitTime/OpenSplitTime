class Api::V1::EventGroupsController < ApiController
  include BackgroundNotifiable
  before_action :set_resource, except: [:index, :create]

  def show
    authorize @resource
    event_group = EventGroup.includes(organization: :stewards, events: [:efforts, :splits]).where(id: @resource.id).first
    render json: event_group, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def import
    authorize @resource

    limited_response = params[:limited_response]&.to_boolean
    importer = ETL::ImporterFromContext.build(@resource, params, current_user)
    importer.import
    errors = importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }

    if importer.strict?
      if errors.present?
        render json: {errors: errors}, status: :unprocessable_entity
      else
        ETL::EventGroupImportProcess.perform!(@resource, importer)
        response = limited_response ? {} : importer.saved_records
        render json: response, status: :created
      end
    else
      ETL::EventGroupImportProcess.perform!(@resource, importer)
      response = limited_response ? {} :
                     {saved_records: importer.saved_records.map { |record| ActiveModel::SerializableResource.new(record) },
                      destroyed_records: importer.destroyed_records.map { |record| ActiveModel::SerializableResource.new(record) },
                      errors: errors}
      render json: response, status: importer.saved_records.present? ? :created : :unprocessable_entity
    end
  end

  def import_csv_raw_times
    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(events: :splits).first

    params[:data_format] = :csv_raw_times
    importer = ETL::ImporterFromContext.build(@resource, params, current_user)
    importer.import
    errors = importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }
    raw_times = RawTime.where(id: importer.saved_records)

    enriched_raw_times = raw_times.with_relation_ids

    raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: enriched_raw_times)
    times_container = SegmentTimesContainer.new(calc_model: :stats)
    raw_time_rows.each { |rtr| VerifyRawTimeRow.perform(rtr, times_container: times_container) }

    raw_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)

    render json: {data: {rawTimeRows: raw_time_rows.map { |row| row.serialize }}, errors: errors}, status: :ok
  end

  def pull_raw_times

    # This endpoint searches for un-pulled raw_times belonging to the event_group,
    # selects a batch, marks them as pulled, combines them into time_rows, and returns them
    # to the live entry page.

    # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
    # If params[:force_pull] == true, raw_times without a matching split_time will be pulled
    # even if they are marked as already having been pulled.

    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(events: :splits).first

    force_pull = params[:force_pull]&.to_boolean
    default_record_limit = 50
    record_limit = params.dig(:page, :size) || default_record_limit

    scoped_raw_times = force_pull ? event_group.raw_times.unmatched : event_group.raw_times.unconsidered

    # Order should be by absolute time ascending, and where absolute time is nil, then by entered time ascending.
    # This ordering is important to minimize the risk of incorrectly ordered times in multi-lap events.
    raw_times = scoped_raw_times.order(:absolute_time, :entered_time).limit(record_limit)
    enriched_raw_times = raw_times.with_relation_ids

    raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: enriched_raw_times)
    times_container = SegmentTimesContainer.new(calc_model: :stats)
    raw_time_rows.each { |rtr| VerifyRawTimeRow.perform(rtr, times_container: times_container) }

    raw_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
    report_raw_times_available(event_group)

    render json: {data: {rawTimeRows: raw_time_rows.map { |row| row.serialize }}}, status: :ok
  end

  def enrich_raw_time_row

    # This endpoint accepts a single raw_time_row and returns an identical raw_time_row
    # with data_status, split_time_exists, lap, and other attributes set

    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(:events).first

    raw_times_data = params[:data] || ActionController::Parameters.new({})
    if raw_times_data[:raw_time_row]
      parsed_row = parse_raw_times_data(raw_times_data)
      enriched_row = EnrichRawTimeRow.perform(event_group: event_group, raw_time_row: parsed_row)

      render json: {data: {rawTimeRow: enriched_row.serialize}}, status: :ok
    else
      render json: {errors: [{title: 'Request must be in the form of {data: {rawTimeRow: {rawTimes: [{...}]}}}'}]}, status: :unprocessable_entity
    end
  end

  def submit_raw_time_rows

    # This endpoint accepts an array of raw_time_rows, verifies them, saves raw_times and saves or updates
    # related split_time data where appropriate, and returns the others.

    # In all instances, raw_times having bad split_name or bib_number data will be returned.
    # When params[:force_submit] is false/nil, all times having bad data status and all duplicate times will be returned.
    # When params[:force_submit] is true, bad and duplicate times will be forced through.

    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(:events).first

    data = params[:data] || ActionController::Parameters.new({})
    errors = []
    raw_time_rows = []

    data.values.each do |raw_times_data|
      if raw_times_data[:raw_time_row]
        raw_time_rows << parse_raw_times_data(ActionController::Parameters.new(raw_times_data))
      else
        errors << {title: 'Request must be in the form of {data: {0: {rawTimeRow: {...}}, 1: {rawTimeRow: {...}}}}',
                   detail: {attributes: raw_times_data}}
      end
    end

    if errors.empty?
      force_submit = !!params[:force_submit]&.to_boolean
      response = Interactors::SubmitRawTimeRows.perform!(event_group: event_group, raw_time_rows: raw_time_rows,
                                                         force_submit: force_submit, mark_as_pulled: true, current_user_id: current_user.id)
      problem_rows = response.resources[:problem_rows]
      report_raw_times_available(event_group)

      render json: {data: {rawTimeRows: problem_rows.map(&:serialize)}}, status: :created
    else
      render json: {errors: errors}, status: :unprocessable_entity
    end
  end

  def trigger_raw_times_push
    authorize @resource
    report_raw_times_available(@resource)
    render json: {message: "Time records push notifications sent for #{@resource.name}"}
  end

  def not_expected
    authorize @resource
    event_group = EventGroup.where(id: @resource).includes(events: :splits).first
    response = FindNotExpectedBibs.perform(event_group, params[:split_name])

    if response.errors.present?
      render json: {errors: response.errors}, status: :unprocessable_entity
    else
      render json: {data: {bib_numbers: response.bib_numbers}}, status: :ok
    end
  end

  private

  def parse_raw_times_data(raw_times_data)
    raw_time_row_attributes = raw_times_data.require(:raw_time_row).permit(raw_times: RawTimeParameters.permitted)
    raw_times_attributes = raw_time_row_attributes[:raw_times] || {}

    raw_times = raw_times_attributes.values.map do |attributes|
      raw_time = attributes[:id].blank? ? RawTime.new : RawTime.find_or_initialize_by(id: attributes[:id])
      raw_time.assign_attributes(attributes.except(:id))
      raw_time
    end

    RawTimeRow.new(raw_times)
  end
end
