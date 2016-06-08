class Live::ProgressReportController < Live::BaseController

  def show
    event = Event.find(params[:id])
    authorize :progress_report, :show?
    @progress_display = EventProgressDisplay.new(event)
  end

  private

end
