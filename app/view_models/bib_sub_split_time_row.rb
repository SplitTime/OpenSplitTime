# frozen_string_literal: true

class BibSubSplitTimeRow
  DISCREPANCY_THRESHOLD = 5.minutes
  attr_reader :bib_number, :effort

  def initialize(args)
    @bib_number = args[:bib_number]
    @effort = args[:effort] || Effort.null_record
    @live_times = args[:live_times] || []
    @split_times = args[:split_times] || []
    @event = args[:event]
  end

  def full_name
    effort.full_name
  end

  def recorded_times
    live_times.group_by(&:source_text).transform_values do |times_array|
      {military_times: times_array.map { |lt| lt.military_time(time_zone) },
       split_time_ids: times_array.map(&:split_time_id)}
    end
  end

  def result_times
    split_times.map do |split_time|
      {lap: split_time.lap,
       military_time: split_time.military_time,
       data_status: split_time.data_status,
       time_and_optional_lap: time_and_optional_lap(split_time)}
    end
  end

  def largest_discrepancy
    times_in_seconds = joined_military_times.map { |military_time| ActiveSupport::TimeZone[time_zone].parse(military_time).seconds_since_midnight }.sort
    adjusted_times = times_in_seconds.map { |seconds| (seconds - times_in_seconds.first) > 12.hours ? (seconds - 24.hours).to_i : seconds }.sort
    (adjusted_times.last - adjusted_times.first).to_i
  end

  def problem?
    (largest_discrepancy > DISCREPANCY_THRESHOLD) || effort.null_record?
  end

  private

  attr_reader :live_times, :split_times, :event

  def time_and_optional_lap(split_time)
    event.multiple_laps? ? "Lap #{split_time.lap}: #{split_time.military_time}" : split_time.military_time
  end

  def time_zone
    event.home_time_zone
  end

  def joined_military_times
    split_times.map(&:military_time) | live_times.map { |lt| lt.military_time(time_zone) }
  end
end
