# frozen_string_literal: true

class ProgressNotifier < BaseNotifier
  def post_initialize(args)
    @effort_data = args[:effort_data]
  end

  private

  attr_reader :effort_data

  def subject
    "Update for #{effort_data[:full_name]} at #{effort_data[:event_name]} from OpenSplitTime"
  end

  def message
    <<~MESSAGE
      #{effort_data[:full_name]} made progress at #{effort_data[:event_name]}:
      #{times_text}
      Results on OpenSplitTime: #{shortened_url}
    MESSAGE
  end

  def shortened_url
    key = Shortener::ShortenedUrl.generate!(effort_path).unique_key

    "#{OST::SHORTENED_URI}/#{key}"
  end

  def effort_path
    "/efforts/#{effort_data[:effort_slug]}"
  end

  def times_text
    effort_data[:split_times_data].map do |split_time_data|
      follower_update_body_text(split_time_data)
    end.join("\n")
  end

  def follower_update_body_text(split_time_data)
    "#{split_time_data[:split_name]} " +
        "(Mile #{(split_time_data[:split_distance] / UnitConversions::METERS_PER_MILE).round(1)}), " +
        "#{split_time_data[:absolute_time_local]}, " +
        "elapsed: #{split_time_data[:elapsed_time]}" +
        "#{split_time_data[:stopped_here] ? ' and stopped there' : ''}"
  end
end
