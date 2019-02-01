# frozen_string_literal: true

module MailHelper
  def follower_update_body_text(split_time_data)
    "#{split_time_data[:split_name]} " +
        "(Mile #{(split_time_data[:split_distance] / UnitConversions::METERS_PER_MILE).round(1)}), " +
        "#{split_time_data[:absolute_time_local]}, " +
        "elapsed time: #{split_time_data[:elapsed_time]}" +
        "#{split_time_data[:stopped_here] ? ' and stopped there' : ''}"
  end
end
