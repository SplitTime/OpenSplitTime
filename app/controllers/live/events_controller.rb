class Live::EventsController < Live::BaseController

  before_action :set_event

  def live_entry
    authorize @event
    verify_available_live(@event)
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
    @event = Event.where(id: @event.id).includes(:splits).includes(:event_group).first
    aid_station = @event.aid_stations.find_by(id: params[:aid_station]) || @event.ordered_aid_stations.first
    @aid_station_detail = AidStationDetail.new(event: @event, aid_station: aid_station, params: prepared_params)
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end
end
