class Live::EventsController < Live::BaseController

  before_action :set_event

  def live_entry
    authorize @event
  end

  def aid_station_report
    authorize @event
    @aid_stations_display = AidStationsDisplay.new(@event)
  end

  def progress_report
    authorize @event
    @progress_display = EventProgressDisplay.new(@event, params[:past_due_threshold])
  end

  def get_event_data

    # This endpoint requires only an event_id, which is passed via the URL as params[:id]
    # It returns a json containing eventId, eventName, and detailed split info
    # for all splits associated with the event.

    authorize @event
    render partial: 'event_data.json.ruby'
  end

  # This endpoint is called on any of the following conditions:
  # - split selector is changed
  # - user tabs or clicks out of bib # field
  # - user tabs or clicks out of time in or time out fields

  def get_live_effort_data

    # Params should include at least splitId and bibNumber. Params may also include timeIn and timeOut.
    # This endpoint returns { success: true } if a split and effort are found.
    # It also returns as many of the following as it can determine:
    # { effortId (integer), name (string), reportedText (string), dropped (bool), finished (bool),
    # timeFromLastReported ("hh:mm"), timeInAid ("mm minutes"), timeInExists (bool), timeOutExists (bool),
    # timeInStatus ('good', 'questionable', 'bad'), timeOutStatus ('good', 'questionable', 'bad') }

    authorize @event
    render partial: 'live_effort_data.json.ruby'
  end

  def get_file_effort_data

    # Param should be an unaltered file. Assume CSV format for now.
    # This endpoint interprets and verifies rows from the file and returns
    # return_rows containing all data necessary to populate the provisional data cache.

    authorize @event
    @file_transformer = LiveFileTransformer.new(params[:file])
    render partial: 'file_effort_data_report.json.ruby'
  end

  def set_times_data

    # Each time_row should include splitId, bibNumber, timeIn (military), timeOut (military),
    # pacerIn (boolean), and pacerOut (boolean). This action ingests time_rows, converts and
    # verifies data, creates new split_times for valid time_rows, and returns invalid time_rows intact.

    authorize @event
    @live_importer = LiveTimeRowImporter.new(@event, params[:timeRows])
    render partial: 'set_times_data_report.json.ruby'
  end

  def aid_station_degrade
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    aid_station.degrade_status
    redirect_to aid_station_report_live_event_path(@event)
  end

  def aid_station_advance
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    aid_station.advance_status
    redirect_to aid_station_report_live_event_path(@event)
  end

  def aid_station_detail
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    @aid_station_detail = AidStationDetail.new(aid_station)
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

end
