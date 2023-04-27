# frozen_string_literal: true

module BackgroundNotifiable
  extend ActiveSupport::Concern

  def report_raw_times_available(event_group)
    Turbo::StreamsChannel.broadcast_render_to [event_group, :live_times],
                                              partial: "raw_times/live_times_available",
                                              locals: {
                                                unreviewed_count: event_group.raw_times.unreviewed.size,
                                                unmatched_count: event_group.raw_times.unmatched.size,
                                              }
    # channel = "event_groups:#{event_group.id}"
    # message = {
    #   event: "raw_times_available",
    #   detail: {unreviewed: event_group.raw_times.unreviewed.size,
    #            unmatched: event_group.raw_times.unmatched.size}
    # }
    # ::ActionCable.server.broadcast(channel, message)
  end
end
