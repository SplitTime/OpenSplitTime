class Api::V1::StagingsController < ApiController
  before_action :set_event, except: :get_uuid

  def get_uuid
    authorize :staging, :get_uuid?
    render json: {uuid: SecureRandom.uuid}
  end

  def get_locations
    authorize @event
    locations = Location.bounded_by(params).first(500)
    render json: locations
  end

  def get_event
    if @event
      authorize @event
      render json: @event
    else
      new_event = Event.new(staging_id: params[:id])
      authorize new_event, :new_staging_event
      render json: new_event
    end
  end

  private

  def set_event
    @event = Event.find_by(staging_id: params[:id])
  end
end