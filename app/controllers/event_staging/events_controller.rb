class EventStaging::EventsController < EventStaging::BaseController

  def new
    authorize :event_staging, :new?
    uuid = SecureRandom.uuid
    redirect_to event_staging_app_path(uuid)
  end

  def app
    @event = Event.find_by(staging_id: params[:staging_id])
    if @event
      authorize @event, :event_staging_app?
    else
      authorize :event_staging, :new?
    end
  end
end