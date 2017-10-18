module BackgroundNotifiable
  extend ActiveSupport::Concern

  RECORDS_PER_UPDATE = 10

  def report_progress(args)
    current = args[:current]
    total = args[:total]
    if background_channel && ((current % RECORDS_PER_UPDATE == 0) || (current == total))
      notifier.publish(channel: background_channel, event: 'update', action: args[:action],
                       resource: args[:resource], current_object: current, total_objects: total)
    end
  end

  def report_status(args)
    notifier.publish(channel: background_channel, event: 'update', message: args[:message]) if background_channel
  end

  def report_error(args)
    notifier.publish(channel: background_channel, event: 'error', message: args[:message]) if background_channel
  end

  def report_response(response)
    if response.successful?
      report_status(message: response.message)
    else
      report_error(message: "#{response.message}: #{response.error_report}")
    end
  end

  def report_live_times_available(event)
    channel = "live_times_available_#{event.id}"
    message = {count: event.live_times.unconsidered.size}
    Pusher.trigger(channel, 'update', message)
  end

  private

  def notifier
    BackgroundNotifier
  end
end
