# frozen_string_literal: true

class AnalyzeTrafficFrequency
  include Interactors::Errors
  include TimeFormats

  ROW_LIMIT = 100

  def self.perform(args)
    new(args).perform
  end

  def initialize(args)
    @event_group = args[:event_group]
    @split_name = args[:split_name]
    @band_width = args[:band_width]
  end

  def perform
    Interactors::Response.new([], message, resources)
  end

  private

  attr_reader :event_group, :split_name, :band_width, :errors

  def message
    case
    when row_limit_exceeded?
      "Too many rows to analyze. Use a lower frequency."
    when split_times.empty?
      "No entrants have arrived at this aid station."
    else
      "Traffic at #{split_name} in increments of #{band_width / 1.minute} minutes"
    end
  end

  def resources
    {table: table}
  end

  def table
    return [] if row_limit_exceeded?
    split_times.each do |split_time|
      low_time = band_time(split_time)
      bands[low_time][split_time.sub_split_kind.downcase.to_sym] += 1
    end
    bands.map { |datetime, hash| {low_time: datetime, count: hash} }
  end

  def row_limit_exceeded?
    (latest_day_and_time - earliest_band_time) / band_width > ROW_LIMIT
  end

  def bands
    @bands ||= boundaries.map { |low_time| [low_time, Hash.new(0)] }.to_h
  end

  def boundaries
    result = []
    current_time = earliest_band_time
    while current_time <= latest_day_and_time
      result << current_time
      current_time += band_width
    end
    result
  end

  def earliest_band_time
    band_time(earliest_split_time)
  end

  def band_time(split_time)
    day_and_time = split_time.day_and_time
    midnight = day_and_time.midnight
    increment = day_and_time.seconds_since_midnight.to_i / band_width * band_width
    midnight + increment
  end

  def earliest_split_time
    split_times.min_by(&:day_and_time)
  end

  def latest_day_and_time
    @latest_day_and_time ||= split_times.max_by(&:day_and_time).day_and_time
  end

  def split_times
    @split_times ||= SplitTime.with_time_record_matchers.joins(:split).where(effort: efforts, splits: {parameterized_base_name: parameterized_split_name})
  end

  def efforts
    Effort.where(event: event_group.events)
  end

  def parameterized_split_name
    split_name.parameterize
  end
end
