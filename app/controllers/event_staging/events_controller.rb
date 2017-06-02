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
    return if params[:staging_id] == 'new'
    @event = params[:staging_id].uuid? ?
        Event.find_by(staging_id: params[:staging_id]) :
        Event.friendly.find(params[:staging_id])
  end
end
