class Live::EventsController < Live::BaseController

  before_action :set_event

  def live_entry
    authorize @event
    verify_available_live
  end

  def aid_station_report
    authorize @event
    @aid_stations_display = AidStationsDisplay.new(event: @event)
  end

  def progress_report
    authorize @event
    @progress_display = LiveProgressDisplay.new(event: @event, past_due_threshold: params[:past_due_threshold])
  end

  def effort_table
    authorize @event
    effort = Effort.friendly.find(params[:effort_id])
    @presenter = EffortShowView.new(effort: effort)
    render partial: 'effort_table'
  end

  def aid_station_detail
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    params[:efforts] ||= 'expected'
    @aid_station_detail = AidStationDetail.new(event: @event, aid_station: aid_station)
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end

  def verify_available_live
    unless @event.available_live
      flash[:danger] = "#{@event.name} is not available for live entry. Please enable live entry access through the event stage/admin page."
      redirect_to event_path(@event)
    end
  end
end
