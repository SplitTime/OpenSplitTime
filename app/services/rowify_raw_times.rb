# frozen_string_literal: true

# event_group should include events: :splits
# raw_times must include effort_ids (e.g., by using RawTime.with_relation_ids)

class RowifyRawTimes
  def self.build(args)
    new(args).build
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event_group, :raw_times],
                           exclusive: [:event_group, :raw_times],
                           class: self.class)
    @event_group = args[:event_group]
    @raw_times = args[:raw_times]
    validate_setup
  end

  def build
    add_lap_to_raw_times
    add_entered_time_from_absolute # See note below
    raw_time_pairs = RawTimePairer.pair(event_group: event_group, raw_times: raw_times).map(&:compact)
    raw_time_pairs.map(&method(:build_time_row))
  end

  private

  attr_reader :event_group, :raw_times
  delegate :home_time_zone, to: :event_group

  def add_lap_to_raw_times
    raw_times.reject(&:lap).each do |raw_time|
      if single_lap_event_group? || single_lap_event?(raw_time)
        raw_time.lap = 1
      elsif raw_time.effort_id.nil? || raw_time.split_id.nil?
        raw_time.lap = nil
      elsif raw_time.absolute_time
        raw_time.lap = expected_lap(raw_time, :absolute_time_local, raw_time.absolute_time)
      elsif raw_time.military_time
        raw_time.lap = expected_lap(raw_time, :military_time, raw_time.military_time)
      else
        raw_time.lap = nil
      end
    end
  end

  def expected_lap(raw_time, subject_attribute, subject_value)
    FindExpectedLap.perform(effort: indexed_efforts[raw_time.effort_id],
                            subject_attribute: subject_attribute,
                            subject_value: subject_value,
                            split_id: raw_time.split_id,
                            bitkey: raw_time.bitkey)
  end

  # This should be removed after OST Remote changes are
  # well baked, circa January 2021.
  def add_entered_time_from_absolute
    raw_times.reject(&:entered_time).each do |rt|
      rt.entered_time = rt.military_time(home_time_zone)
    end
  end

  def build_time_row(raw_time_pair)
    raw_time = raw_time_pair.first
    effort, event, split = indexed_efforts[raw_time.effort_id], indexed_events[raw_time.event_id], indexed_splits[raw_time.split_id]
    RawTimeRow.new(raw_time_pair, effort, event, split, [])
  end

  def single_lap_event_group?
    @single_lap_event_group ||= event_group.single_lap?
  end

  def single_lap_event?(raw_time)
    indexed_events[raw_time.event_id]&.single_lap?
  end

  def indexed_events
    @indexed_events ||= event_group.events.index_by(&:id)
  end

  def indexed_splits
    @indexed_splits ||= indexed_events.values.flat_map(&:splits).index_by(&:id)
  end

  def indexed_efforts
    @indexed_efforts ||= Effort.where(id: effort_ids).includes(:event, split_times: :split).index_by(&:id)
  end

  def effort_ids
    @effort_ids ||= raw_times.map(&:effort_id).compact.uniq
  end

  def validate_setup
    raise ArgumentError, 'All raw_times must match the provided event_group' unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
  end
end
