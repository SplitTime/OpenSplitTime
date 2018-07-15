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
    importer = ETL::ImporterFromContext.build(@event, params, current_user)
    importer.import
    errors = importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }

    if importer.strict?
      if errors.present?
        render json: {errors: errors}, status: :unprocessable_entity
      else
        ETL::EventImportProcess.perform!(@event, importer)
        render json: importer.saved_records, status: :created
      end
    else
      ETL::EventImportProcess.perform!(@event, importer)
      render json: {saved_records: importer.saved_records.map { |record| ActiveModel::SerializableResource.new(record) },
                    destroyed_records: importer.destroyed_records.map { |record| ActiveModel::SerializableResource.new(record) },
                    errors: errors},
             status: importer.saved_records.present? ? :created : :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end

  def authorize_event
    authorize @event
  end
end
