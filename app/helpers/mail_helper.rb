# frozen_string_literal: true

module MailHelper

  def follower_update_body_text(split_time_data)
    "#{split_time_data[:split_name]} " +
        "(Mile #{split_time_data[:split_distance].meters.to.miles.round(1)}), " +
        "#{split_time_data[:day_and_time]}, " +
        "elapsed time: #{split_time_data[:elapsed_time]}" +
        "#{split_time_data[:stopped_here] ? ' and stopped there' : ''}"
  end

  def link_to_effort_path(effort_slug)
    effort_path(effort_slug)
  end

  def link_to_event_spread_path(event_slug)
    event_spread_path(event_slug)
  end
end
