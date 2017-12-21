class EventStaging::EventsController < EventStaging::BaseController
  before_action :set_event

  def app
    if @event
      authorize @event, :event_staging_app?
    else
      authorize Event, :new_staging?
    end
  end

  private

  def set_event
    return if params[:id] == 'new'
    @event = Event.friendly.find(params[:id])
  end
end
