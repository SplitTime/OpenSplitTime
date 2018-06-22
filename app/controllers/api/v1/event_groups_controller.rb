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

    importer = ETL::ImporterFromContext.build(@resource, params, current_user)
    importer.import
    errors = importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }

    if importer.strict?
      if errors.present?
        render json: {errors: errors}, status: :unprocessable_entity
      else
        ETL::EventGroupImportProcess.perform!(@resource, importer)
        render json: importer.saved_records, status: :created
      end
    else
      ETL::EventGroupImportProcess.perform!(@resource, importer)
      render json: {saved_records: importer.saved_records.map { |record| ActiveModel::SerializableResource.new(record) },
                    destroyed_records: importer.destroyed_records.map { |record| ActiveModel::SerializableResource.new(record) },
                    errors: errors},
             status: importer.saved_records.present? ? :created : :unprocessable_entity
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
    raw_times = scoped_raw_times.order(:absolute_time, :entered_time).limit(record_limit).with_relation_ids

    raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: raw_times)

    raw_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
    report_raw_times_available(event_group)
    render json: raw_time_rows, status: :ok
  end

  def trigger_time_records_push
    authorize @resource
    report_raw_times_available(@resource)
    render json: {message: "Time records push notifications sent for #{@resource.name}"}
  end
end
