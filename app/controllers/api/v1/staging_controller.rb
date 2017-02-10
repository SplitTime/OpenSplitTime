class Api::V1::StagingController < ApiController
  before_action :set_event

  # GET /api/vi/staging/:uuid/get_locations?west=&east=&south=&north=
  def get_locations
    authorize @event
    locations = Location.bounded_by(get_locations_params.transform_values(&:to_f)).first(500)
    render json: locations
  end

  # GET /api/v1/staging/:uuid/get_event
  def get_event
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
        render json: {error: 'invalid uuid'}
      end
    end
  end

  private

  def set_event
    @event = Event.find_by(staging_id: params[:staging_id])
  end

  def get_locations_params
    params.permit(:west, :east, :south, :north)
  end
end