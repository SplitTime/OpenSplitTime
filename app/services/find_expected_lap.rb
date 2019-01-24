# frozen_string_literal: true

class FindExpectedLap
  def self.perform(args)
    new(args).perform
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :subject_attribute, :subject_value, :split_id, :bitkey],
                           exclusive: [:effort, :subject_attribute, :subject_value, :split_id, :bitkey])
    @effort = args[:effort]
    @subject_attribute = args[:subject_attribute]
    @subject_value = args[:subject_value]
    @split_id = args[:split_id]
    @bitkey = args[:bitkey]
  end

  def perform
    return 1 if maximum_lap == 1
    missing_lap || (location_highest_lap + 1).clamp(1, maximum_lap)
  end

  private

  attr_reader :effort, :subject_attribute, :subject_value, :split_id, :bitkey
  delegate :event, to: :effort

  def missing_lap
    (1..highest_lap).find(&method(:time_fits_missing?))
  end

  def time_fits_missing?(lap)
    return if indexed_location_times[lap]
    previous_time = previous_value(lap)
    next_time = next_value(lap)
    previous_time.present? && next_time.present? && subject_value.between?(previous_time, next_time)
  end

  def previous_value(lap)
    SplitTimeFinder.prior(time_point: subject_time_point(lap), effort: effort, lap_splits: lap_splits)&.send(subject_attribute) || start_value
  end

  def next_value(lap)
    SplitTimeFinder.next(time_point: subject_time_point(lap), effort: effort, lap_splits: lap_splits)&.send(subject_attribute)
  end

  def subject_time_point(lap)
    TimePoint.new(lap, split_id, bitkey)
  end

  def start_value
    @start_value ||= TimeConversion.absolute_to_hms(effort.start_time)
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
