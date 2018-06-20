# frozen_string_literal: true

class RowifyRawTimes
  def self.build(args)
    new(args).build
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:event_group, :raw_times], exclusive: [:event_group, :raw_times], class: self.class)
    @event_group = args[:event_group]
    @raw_times = args[:raw_times]
    validate_setup
  end

  def build
    add_lap_to_raw_times
    raw_time_pairs = RawTimePairer.pair(event_group: event_group, raw_times: raw_times).map(&:compact)

    raw_time_pairs.each do |raw_time_pair|
      raw_time = raw_time_pair.compact.first
      effort = indexed_efforts[raw_time.effort_id]
      event = indexed_events[raw_time.event_id]
      VerifyRawTimes.perform(effort: effort, event: event, raw_times: raw_time_pair) if effort
    end
    raw_time_pairs
  end

  private

  attr_reader :event_group, :raw_times

  def add_lap_to_raw_times
    raw_times.each do |raw_time|
      if single_lap_event_group? || single_lap_event?(raw_time)
        raw_time.lap = 1
      elsif raw_time.effort_id.nil?
        raw_time.lap = nil
      else
        raw_time.lap ||= FindExpectedLap.perform(effort: indexed_efforts[raw_time.effort_id])
      end
    end
  end

  def single_lap_event_group?
    @single_lap_event_group ||= event_group.single_lap?
  end

  def single_lap_event?(raw_time)
    indexed_events[raw_time.event_id]&.single_lap?
  end

  def indexed_events
    @indexed_events ||= event_group.events.includes(:splits).index_by(&:id)
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
