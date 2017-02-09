class Api::V1::StagingsController < ApiController
  before_action :set_event, except: :get_uuid

  def get_uuid
    authorize :staging, :get_uuid?
    render json: {uuid: SecureRandom.uuid}
  end

  def get_locations
    authorize @event
    locations = Location.bounded_by(params)
    render json: locations
  end

  private

  def set_event
    @event = Event.find_by(params[:staging_id])
  end
end