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
    time_record_pairs.map { |time_record_pair| VerifyTimeRecordPair.perform(time_record_pair) }
  end

  private

  attr_reader :event_group, :time_records

  def time_record_pairs
    TimeRecordPairer.pair(event_group: event_group, raw_times: time_records)
  end

  def validate_setup
    raise ArgumentError, 'All raw_times must match the provided event_group' unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
  end
end