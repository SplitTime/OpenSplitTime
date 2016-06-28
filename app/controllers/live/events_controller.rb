class Live::EventsController < Live::BaseController

  before_action :set_event

  def live_entry
    authorize @event
    verify_available_live
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
    if @event.available_live
      render partial: 'event_data.json.ruby'
    else
      render partial: 'live_entry_unavailable.json.ruby'
    end
  end

  # This endpoint is called on any of the following conditions:
  # - split selector is changed
  # - bib # field is changed
  # - time in or time out field is changed

  def get_live_effort_data

    # Params should include at least splitId and bibNumber. Params may also include timeIn and timeOut.
    # This endpoint returns { success: true } if a split and effort are found.
    # It also returns as many of the following as it can determine:
    # { effortId (integer), name (string), reportedText (string), dropped (bool), finished (bool),
    # timeFromLastReported ("hh:mm"), timeInAid ("mm minutes"), timeInExists (bool), timeOutExists (bool),
    # timeInStatus ('good', 'questionable', 'bad'), timeOutStatus ('good', 'questionable', 'bad') }

    authorize @event
    if @event.available_live
      render partial: 'live_effort_data.json.ruby'
    else
      render partial: 'live_entry_unavailable.json.ruby'
    end
  end

  def get_effort_table
    authorize @event
    effort = Effort.find(params[:effortId])
    @effort_show = EffortShowView.new(effort)
    render partial: 'effort_table'
  end

  def post_file_effort_data

    # Param should be an unaltered CSV file.
    # This endpoint interprets and verifies rows from the file and returns
    # return_rows containing all data necessary to populate the provisional data cache.

    authorize @event
    if @event.available_live
      @file_transformer = LiveFileTransformer.new(@event, params[:file], params[:splitId])
      render partial: 'file_effort_data_report.json.ruby'
    else
      render partial: 'live_entry_unavailable.json.ruby'
    end
  end

  def set_times_data

    # Each time_row should include splitId, bibNumber, timeIn (military), timeOut (military),
    # pacerIn (boolean), pacerOut (boolean), and droppedHere (boolean). This action ingests time_rows, converts and
    # verifies data, creates new split_times for valid time_rows, and returns invalid time_rows intact.

    authorize @event
    if @event.available_live
      @live_importer = LiveTimeRowImporter.new(@event, params[:timeRows])
      render partial: 'set_times_data_report.json.ruby'
    else
      render partial: 'live_entry_unavailable.json.ruby'
    end
  end

  def aid_station_degrade
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    report = aid_station.degrade_status
    flash[report[:status]] = report[:text]
    redirect_to aid_station_report_live_event_path(@event)
  end

  def aid_station_advance
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    report = aid_station.advance_status
    flash[report[:status]] = report[:text]
    redirect_to aid_station_report_live_event_path(@event)
  end

  def aid_station_detail
    authorize @event
    aid_station = @event.aid_stations.find(params[:aid_station])
    params[:efforts] ||= 'expected'
    @aid_station_detail = AidStationDetail.new(aid_station)
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def verify_available_live
    unless @event.available_live
      flash[:danger] = "#{@event.name} is not available for live entry. Please enable live entry access through the event stage/admin page."
      redirect_to event_path(@event)
    end
  end

end
