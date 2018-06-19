# frozen_string_literal: true

class RowifyTimeRecords
  def self.build(args)
    new(args).build
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:event_group, :time_records], exclusive: [:event_group, :time_records], class: self.class)
    @event_group = args[:event_group]
    @time_records = args[:time_records]
    validate_setup
  end

  def build
    add_lap_to_time_records
    time_record_pairs.map { |time_record_pair| VerifyTimeRecordPair.perform(time_record_pair) }
  end

  private

  attr_reader :event_group, :time_records

  def add_lap_to_time_records
    time_records.each do |tr|
      tr.lap = 1 if single_lap?(tr)
      tr.lap ||= FindExpectedLap.perform(effort: indexed_efforts[tr.effort_id])
    end
  end

  def single_lap?(time_record)
    single_lap_event_group? || single_lap_event?(time_record)
  end

  def single_lap_event_group?
    @single_lap_event_group ||= !event_group.multiple_laps?
  end

  def single_lap_event?(time_record)
    !indexed_events[time_record.event_id]&.multiple_laps?
  end

  def indexed_events
    @indexed_events ||= event_group.events.index_by(&:id)
  end

  def indexed_efforts
    @indexed_efforts ||= Effort.where(id: effort_ids).includes(split_times: :split).index_by(&:id)
  end

  def time_record_pairs
    TimeRecordPairer.pair(event_group: event_group, raw_times: time_records)
  end

  def validate_setup
    raise ArgumentError, 'All raw_times must match the provided event_group' unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
  end
end