# frozen_string_literal: true

class TimeRecordRowConverter
  def self.convert(args)
    new(args).convert
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :time_records],
                           exclusive: [:event, :time_records, :times_container],
                           class: self.class)
    @event = args[:event]
    @time_records = args[:time_records]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    validate_setup
  end

  def convert
    transformed_rows.reject { |row| row[:identical] }
  end

  def transformed_rows
    effort_data_objects.map { |effort_data| effort_data.response_row }
  end

  def effort_data_objects
    @effort_data_objects ||= time_rows.map do |time_row|
      LiveEffortData.new(event: event,
                         params: time_row,
                         times_container: times_container,
                         ordered_splits: ordered_splits)
    end
  end

  private

  attr_reader :event, :time_records, :times_container
  delegate :home_time_zone, to: :event

  def time_rows
    paired_time_records.map do |left_time_record, right_time_record|
      {split_id: left_time_record&.split_id || right_time_record&.split_id,
       bib_number: left_time_record&.bib_number || right_time_record&.bib_number,
       live_time_id_in: left_time_record.is_a?(LiveTime) ? left_time_record.id : nil,
       live_time_id_out: right_time_record.is_a?(LiveTime) ? right_time_record.id : nil,
       raw_time_id_in: left_time_record.is_a?(RawTime) ? left_time_record.id : nil,
       raw_time_id_out: right_time_record.is_a?(RawTime) ? right_time_record.id : nil,
       time_in: left_time_record&.military_time(home_time_zone),
       time_out: right_time_record&.military_time(home_time_zone),
       pacer_in: left_time_record&.with_pacer,
       pacer_out: right_time_record&.with_pacer,
       dropped_here: left_time_record&.stopped_here || right_time_record&.stopped_here,
       remarks: [left_time_record&.remarks, right_time_record&.remarks].compact.join(' / ')}
    end
  end

  def paired_time_records
    TimeRecordPairer.pair(time_records: time_records)
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def validate_setup
    raise ArgumentError, 'All time_records must match the provided event' unless
        time_records.all? { |tr| tr.event_id.nil? || tr.event_id == event.id }
  end
end
