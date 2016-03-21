class EventSplitsController < ApplicationController

  def destroy
    @event_split = EventSplit.find(params[:id])
    @event_split.destroy
    redirect_to splits_event_url(id: @event_split.event_id)
  end

end