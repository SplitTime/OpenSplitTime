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

  def pull_raw_times

    # This endpoint searches for un-pulled raw_times belonging to the event_group,
    # selects a batch, marks them as pulled, combines them into time_rows, and returns them
    # to the live entry page.

    # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
    # If params[:force_pull] == true, raw_times without a matching split_time will be pulled
    # even if they are marked as already having been pulled.

    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(:events).first

    force_pull = params[:force_pull]&.to_boolean
    default_record_limit = 50
    record_limit = params.dig(:page, :size) || default_record_limit

    scoped_raw_times = force_pull ? event_group.raw_times.unmatched : event_group.raw_times.unconsidered

    # Order should be by absolute time ascending, and where absolute time is nil, then by entered time ascending.
    # This ordering is important to minimize the risk of incorrectly ordered times in multi-lap events.
    raw_times = scoped_raw_times.order(:absolute_time, :entered_time).limit(record_limit)
    enriched_raw_times = raw_times.with_relation_ids

    raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: enriched_raw_times)

    raw_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
    report_raw_times_available(event_group)

    render json: {data: {rawTimeRows: raw_time_rows.map { |row| row.serialize }}}, status: :ok
  end

  def enrich_raw_time_row

    # This endpoint accepts a single raw_time_row and returns an identical raw_time_row
    # with data_status, split_time_exists, lap, and other attributes set
    # and with an effort_overview object (existing splits and time data for the related effort)

    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(:events).first

    raw_times_data = params[:data] || ActionController::Parameters.new({})
    if raw_times_data[:raw_time_row]
      result_row = parse_raw_times_data(raw_times_data, event_group)

      render json: {data: {rawTimeRow: result_row.serialize}}, status: :ok
    else
      render json: {errors: [{title: 'Request must be in the form of {data: {rawTimeRow: {rawTimes: [{...}]}}}'}]}, status: :unprocessable_entity
    end
  end

  def submit_raw_time_rows

    # This endpoint accepts an array of raw_time_rows, verifies them,
    # saves those that are good and not duplicates, and returns the others.

    authorize @resource
    event_group = EventGroup.where(id: @resource.id).includes(:events).first

    data = params[:data] || ActionController::Parameters.new({})
    errors = []
    enriched_raw_time_rows = []

    data.values.each do |raw_times_data|
      if raw_times_data[:raw_time_row]
        result_row = parse_raw_times_data(ActionController::Parameters.new(raw_times_data), event_group)
        enriched_raw_time_rows << result_row
      else
        errors << {title: 'Request must be in the form of {data: {0: {rawTimeRow: {...}}, 1: {rawTimeRow: {...}}}}',
                   detail: {attributes: raw_times_data}}
      end
    end

    if errors.empty?
      partition_method = params[:force_submit]&.to_boolean ? :itself : :clean?
      clean_rows, problem_rows = enriched_raw_time_rows.partition(&partition_method)
      saved_rows = []

      clean_rows.each do |rtr|
        ActiveRecord::Base.transaction do
          rtr_errors = []

          rtr.raw_times.each do |raw_time|
            raw_time.event_group_id = event_group.id
            raw_time.source ||= "Live Entry (#{current_user.id})"
            unless raw_time.save
              rtr_errors << jsonapi_error_object(raw_time)
            end
          end

          if rtr_errors.present?
            rtr.errors ||= []
            rtr.errors << rtr_errors
            problem_rows << rtr
            raise ActiveRecord::Rollback
          else
            saved_rows << rtr
          end
        end
      end

      importer = OpenStruct.new(saved_records: saved_rows.flat_map(&:raw_times))
      ETL::EventGroupImportProcess.perform!(event_group, importer)
      render json: {data: {rawTimeRows: problem_rows.map(&:serialize)}}
    else
      render json: {errors: errors}, status: :unprocessable_entity
    end
  end

  def trigger_time_records_push
    authorize @resource
    report_raw_times_available(@resource)
    render json: {message: "Time records push notifications sent for #{@resource.name}"}
  end

  private

  def parse_raw_times_data(raw_times_data, event_group)
    raw_time_row = raw_times_data.require(:raw_time_row).permit(raw_times: RawTimeParameters.permitted)
    raw_times_attributes = raw_time_row[:raw_times] || {}
    raw_times = raw_times_attributes.values.map { |attributes| RawTime.new(attributes) }
    request_row = RawTimeRow.new(raw_times)
    EnrichRawTimeRow.perform(event_group: event_group, raw_time_row: request_row)
  end
end
