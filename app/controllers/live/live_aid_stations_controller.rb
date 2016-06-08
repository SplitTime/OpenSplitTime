class Live::LiveAidStationsController < Live::BaseController

  def show
    event = Event.find(params[:id])
    authorize :live_aid_stations, :show?
    @aid_stations_display = AidStationsDisplay.new(event)
  end

  private

end
