# frozen_string_literal: true

module BackgroundNotifiable
  extend ActiveSupport::Concern

  def report_progress(args)
    current = args[:current]
    total = args[:total]
    records_per_update = total / 20
    if background_channel && ((current % records_per_update == 0) || (current == 1) || (current == total))
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

  def report_interactor_response(response)
    if response.successful?
      report_status(message: response.message)
    else
      report_status(message: response.message_with_error_report)
    end
  end

  def report_live_times_available(resource)
    channel = "live-times-available.#{resource.class.to_s.underscore}.#{resource.id}"
    message = {unconsidered: resource.live_times.unconsidered.size,
               unmatched: resource.live_times.unmatched.size}
    Pusher.trigger(channel, 'update', message)
  end

  private

  def notifier
    BackgroundNotifier
  end
end
