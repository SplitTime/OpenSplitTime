class EventStaging::EventsController < EventStaging::BaseController

  def new
    skip_authorization
    uuid = SecureRandom.uuid
    redirect_to event_staging_app_path(uuid)
  end

  def app
    @event = Event.find_by(staging_id: params[:staging_id])
    if @event
      authorize @event, :event_staging_app?
    else
      authorize Event, :new_staging?
    end
  end
end
