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
    @progress_display = EventProgressDisplay.new(@event)
  end

  def get_event_data
    authorize @event
    render partial: 'event_data.json.ruby'
  end

# This endpoint gets called when the admin enters a "bib" number in the live_entry UI.
#
  def get_effort
    # Here look up the effort and populate the json array with data
    # needed for front end processing. The assumption is that this endpoint
    # will take the splitId, bibNumber and eventId used to populate the following fields:
    # Name, Last Reported, Split From, and Time Spent
    #
    # Split From and Time Spent fields are not populated until Time In and Time Out fields are entered
    # Get bib number like this: params[:bibNumber]
    # Event ID is within the url param
    #
    # If the lookup fails here (bibNumber or eventId is incorrect), return { success: false }
    # lastReportedSplitTime comes from the splits table for this "effort"
    # estimatedTime range
    authorize @event
    render partial: 'effort_data.json.ruby'
  end

  def get_time_from_last

    # params must include effortId, splitId, lastReportedSplitId, lastReportedBitkey, and timeIn (military time)
    # This endpoint returns a hash of three elements: {success (boolean),
    # timeFromLastReported (formatted string "hh:mm"), and timeFromStartIn (seconds) }

    authorize @event
    render partial: 'time_from_last.json.ruby'
   end

  def get_time_spent

    # params must include effortId, splitId, timeFromStartIn (seconds from start), timeOut (military time)
    # This returns a hash of three elements: {success (boolean), time_in_aid (number of minutes),
    # and time_from_start_out (seconds from start)}

    authorize @event
    render partial: 'time_spent.json.ruby'
  end

  def verify_times_data

    # params must include effortId, splitId, timeFromStartIn, timeFromStartOut
    # This returns a hash of five elements: {success (boolean), timeInExists (boolean), timeOutExists (boolean),
    # timeInStatus ('bad', 'questionable', or 'good'), and timeOutStatus ('bad', 'questionable', or 'good')}

    authorize @event
    render partial: 'verify_times.json.ruby'
  end

  def set_times_data

    authorize @event
    # TODO: MARK!
    # Efforts come in as an array
    # access efforts as params[:efforts]
    render :json => {
        success: true,
        message: params[:efforts]
    }
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

  private

  def set_event
    @event = Event.find(params[:id])
  end

end
