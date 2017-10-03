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
    if params[:split_name]
      split = @event.splits.find_by(base_name: params[:split_name])
      aid_station = @event.aid_stations.find_by(split_id: split.id) if split
    else
      aid_station = @event.aid_stations.find_by(id: params[:aid_station])
    end
    aid_station ||= @event.aid_stations.find_by(split_id: @event.ordered_split_ids.first)
    @aid_station_detail = AidStationDetail.new(event: @event, aid_station: aid_station, params: prepared_params)
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end
end
