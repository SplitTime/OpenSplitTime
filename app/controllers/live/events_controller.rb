class Live::EventsController < Live::BaseController

  before_action :set_event

  def aid_station_report
    authorize @event

    @presenter = EventWithEffortsPresenter.new(event: @event, params: params, current_user: current_user)
    @aid_stations_display = AidStationsDisplay.new(event: @event)
  end

  def progress_report
    authorize @event

    @presenter = EventWithEffortsPresenter.new(event: @event, params: params, current_user: current_user)
    @progress_display = LiveProgressDisplay.new(event: @event, past_due_threshold: params[:past_due_threshold])
  end

  def aid_station_detail
    authorize @event

    event = Event.where(id: @event.id).includes(:splits, :event_group).first
    @presenter = EventWithEffortsPresenter.new(event: event, params: params, current_user: current_user)
    parameterized_split_name = params[:parameterized_split_name]
    @aid_station_detail = AidStationDetail.new(event: event, parameterized_split_name: parameterized_split_name, params: prepared_params)
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end
end
