class Live::EventGroupsController < Live::BaseController

  before_action :set_event_group

  def live_entry
    authorize @event_group
    @presenter = EventGroupPresenter.new(@event_group, params, current_user)
    verify_available_live(@event_group)
    render :new_live_entry
  end

  private

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:id])
  end
end
