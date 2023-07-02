class Live::EventGroupsController < Live::BaseController
  before_action :set_event_group
  before_action :authorize_event_group

  # GET /live/event_groups/1/live_entry
  def live_entry
    @presenter = EventGroupPresenter.new(@event_group, params, current_user)
    verify_available_live(@event_group)
  end

  # GET /live/event_groups/1/trigger_raw_times_push
  def trigger_raw_times_push
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def authorize_event_group
    authorize @event_group
  end

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:id])
  end
end
