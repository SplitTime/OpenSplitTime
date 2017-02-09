class Api::V1::StagingController < ApiController
  before_action :set_event, except: :get_uuid

  def get_uuid
    authorize :staging, :get_uuid?
    render json: {uuid: SecureRandom.uuid}
  end

  def get_locations
    authorize :staging, :get_locations?
    locations = Location.bounded_by(params.transform_values(&:to_f)).first(500)
    render json: locations
  end

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
end