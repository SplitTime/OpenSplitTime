class Api::V1::StagingController < ApiController
  before_action :set_event, except: [:get_event, :get_countries]

  # GET /api/vi/staging/:staging_id/get_locations?west=&east=&south=&north=
  def get_locations
    authorize @event
    locations = Location.bounded_by(get_locations_params.transform_values(&:to_f)).first(500)
    render json: locations
  end

  # GET /api/v1/staging/:staging_id/get_event
  def get_event
    @event = Event.find_by(staging_id: params[:staging_id])
    if @event
      authorize @event
      render json: @event
    else
      new_event = Event.new(staging_id: params[:staging_id])
      if new_event.staging_id
        authorize new_event, :new_staging_event?
        render json: new_event
      else
        skip_authorization
        render json: {message: 'invalid uuid', error: 'provided staging_id is not a valid uuid'}, status: :bad_request
      end
    end
  end

  # GET /api/v1/staging/get_countries
  def get_countries
    authorize :event_staging, :get_countries?
    render json: {countries: Geodata.standard_countries_subregions}
  end

  private

  def set_event
    @event = Event.find_by(staging_id: params[:staging_id])
    render json: {message: 'event not found'}, status: :not_found unless @event
  end

  def get_locations_params
    params.permit(:west, :east, :south, :north)
  end
end