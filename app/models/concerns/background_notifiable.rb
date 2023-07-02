# frozen_string_literal: true

module BackgroundNotifiable
  extend ActiveSupport::Concern

  def report_raw_times_available(event_group)
    Turbo::StreamsChannel.broadcast_render_to [event_group, :live_times],
                                              partial: "raw_times/live_times_available",
                                              locals: {
                                                event_group: event_group,
                                                unreviewed_count: event_group.raw_times.unreviewed.size,
                                                unmatched_count: event_group.raw_times.unmatched.size,
                                              }
  end
end
