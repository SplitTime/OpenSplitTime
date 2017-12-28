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
    unless @event.friendly_id == params[:id]
      redirect_to request.params.merge(id: @event.friendly_id), status: 301
    end
  end
end
