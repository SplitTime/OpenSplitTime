class Live::EventGroupsController < Live::BaseController

  before_action :set_event_group

  def live_entry
    authorize @event_group
    verify_available_live
  end

  private

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:id])
  end

  def verify_available_live
    unless @event_group.available_live
      flash[:danger] = "#{@event_group.name} is not available for live entry. Please enable live entry access through the event group settings page."
      redirect_to event_group_path(@event_group)
    end
  end
end
