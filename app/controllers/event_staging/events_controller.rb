class EventStaging::EventsController < EventStaging::BaseController
  before_action :set_event, except: :new

  def new
    skip_authorization
    uuid = SecureRandom.uuid
    redirect_to event_staging_app_path(uuid)
  end

  def app
    if @event
      authorize @event, :event_staging_app?
    else
      authorize Event, :new_staging?
    end
  end

  private

  def set_event
    @event = params[:staging_id].uuid? ?
        Event.find_by(staging_id: params[:staging_id]) :
        Event.friendly.find(params[:staging_id])
  end
end
