# frozen_string_literal: true

# args[:effort] should be loaded with {split_times: :split} and event

class VerifyRawTimes
  def self.perform(args)
    new(args).perform
  end
  
  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:raw_times, :effort, :event],
                           exclusive: [:raw_times, :effort, :event, :times_container],
                           class: self.class)
    @raw_times = args[:raw_times]
    @effort = args[:effort]
    @event = args[:event]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    validate_setup
  end

  def perform
    add_existing_count
    append_split_times
    set_data_status
    raw_times
  end
  
  private
  
  attr_reader :raw_times, :effort, :event, :times_container

  def add_existing_count
    raw_times.each do |raw_time|
      raw_time.existing_times_count = effort.split_times.select do |split_time|
        split_time.split_id == raw_time.split_id && split_time.bitkey == raw_time.bitkey
      end.size
    end
  end

  def append_split_times
    raw_times.each { |raw_time| raw_time.new_split_time = SplitTimeFromRawTime.build(raw_time, effort: effort, event: event) }
  end

  def set_data_status
    Interactors::SetEffortStatus.perform(effort, ordered_split_times: ordered_split_times, lap_splits: effort_lap_splits, times_container: times_container)
    raw_times.each do |raw_time|
      raw_time.data_status = raw_time.new_split_time.data_status
    end
  end

  def ordered_split_times
    indexed_existing_split_times = effort.split_times.dup.each { |st| st.data_status = :confirmed if st.good? }.index_by(&:time_point).freeze
    indexed_new_split_times = raw_times.map(&:new_split_time).index_by(&:time_point)
    indexed_split_times = indexed_existing_split_times.merge(indexed_new_split_times)
    effort_time_points.map { |time_point| indexed_split_times[time_point] }.compact
  end

  def effort_lap_splits
    @effort_lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(raw_times_laps.first)
  end

  def effort_time_points
    @effort_time_points ||= effort_lap_splits.flat_map(&:time_points)
  end

  def validate_setup
    raise ArgumentError, 'raw_times must each have an effort_id' unless raw_times_effort_ids.all?
    raise ArgumentError, 'raw_times must each have the same effort_id' if raw_times_effort_ids.uniq.many?
    raise ArgumentError, 'raw_times effort_id must match the provided effort.id' if raw_times_effort_ids.first != effort.id
    raise ArgumentError, 'raw_times must each have a lap' unless raw_times_laps.all?
    raise ArgumentError, 'raw_times must each have the same lap' if raw_times_laps.uniq.many?
    raise ArgumentError, 'raw_times lap is larger than maximum_laps for the event' if event.maximum_laps && raw_times_laps.first > event.maximum_laps
    raise ArgumentError, 'raw_times must each have a split_id' unless raw_times_split_ids.all?
    raise ArgumentError, 'raw_times must each have the same split_id' if raw_times_split_ids.uniq.many?
    raise ArgumentError, 'raw_times split_id must be included in the provided event' unless raw_times_split_ids.all? { |split_id| event_split_ids.include?(split_id) }
    raise ArgumentError, 'raw_times must have different bitkeys' unless raw_times.map(&:bitkey) == raw_times.map(&:bitkey).uniq
  end

  def event_split_ids
    @event_split_ids ||= event.ordered_splits.map(&:id)
  end

  def raw_times_effort_ids
    @raw_times_effort_ids ||= raw_times.map(&:effort_id)
  end

  def raw_times_laps
    @raw_times_laps ||= raw_times.map(&:lap)
  end

  def raw_times_split_ids
    @raw_times_split_ids ||= raw_times.map(&:split_id)
  end
end
