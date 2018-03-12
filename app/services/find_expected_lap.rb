# frozen_string_literal: true

class FindExpectedLap
  def self.perform(args)
    new(args).perform
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :military_time, :split_id, :bitkey],
                           exclusive: [:effort, :military_time, :split_id, :bitkey])
    @effort = args[:effort]
    @military_time = args[:military_time]
    @split_id = args[:split_id]
    @bitkey = args[:bitkey]
  end

  def perform
    missing_lap || (location_highest_lap + 1).clamp(1, maximum_lap)
  end

  private

  attr_reader :effort, :military_time, :split_id, :bitkey
  delegate :event, to: :effort

  def missing_lap
    (1..highest_lap).find { |lap| time_fits_missing(lap) }
  end

  def time_fits_missing(lap)
    return if indexed_location_times[lap]
    previous_time = previous_military_time(lap)
    next_time = next_military_time(lap)
    previous_time && next_time && military_time.between?(previous_time, next_time)
  end

  def previous_military_time(lap)
    SplitTimeFinder.prior(time_point: subject_time_point(lap), effort: effort, lap_splits: lap_splits)&.military_time || start_military_time
  end

  def next_military_time(lap)
    SplitTimeFinder.next(time_point: subject_time_point(lap), effort: effort, lap_splits: lap_splits)&.military_time
  end

  def subject_time_point(lap)
    TimePoint.new(lap, split_id, bitkey)
  end

  def start_military_time
    @start_military_time ||= TimeConversion.absolute_to_hms(effort.start_time)
  end

  def indexed_location_times
    @indexed_location_times ||= split_times.select { |st| (st.split_id == split_id) && (st.bitkey == bitkey) }.index_by(&:lap)
  end

  def location_highest_lap
    @location_highest_lap ||= indexed_location_times.keys.max || 0
  end

  def maximum_lap
    event.laps_unlimited? ? Float::INFINITY : effort.event.laps_required
  end

  def split_times
    @split_times ||= effort.ordered_split_times
  end

  def lap_splits
    @lap_splits ||= event.lap_splits_through(highest_lap)
  end

  def highest_lap
    @highest_lap ||= split_times.map(&:lap).max || 0
  end
end
