class Live::ControlPanelController < Live::BaseController

  before_action :set_event

  def show
    authorize @event
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

end
