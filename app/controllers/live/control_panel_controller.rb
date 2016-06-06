class Live::ControlPanelController < Live::BaseController

  before_action :set_event

  def show
    authorize :control_panel, :show?
    @control_panel = ControlPanelDisplay.new(@event)
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

end
