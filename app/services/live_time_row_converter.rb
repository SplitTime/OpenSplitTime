# frozen_string_literal: true

class LiveTimeRowConverter

  def self.convert(args)
    new(args).convert
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :live_times],
                           exclusive: [:event, :live_times, :times_container],
                           class: self.class)
    @event = args[:event]
    @live_times = args[:live_times]
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

  attr_reader :event, :live_times, :times_container
  delegate :home_time_zone, to: :event

  def time_rows
    paired_live_times.map do |left_live_time, right_live_time|
      {split_id: left_live_time&.split_id || right_live_time&.split_id,
       bib_number: left_live_time&.bib_number || right_live_time&.bib_number,
       live_time_id_in: left_live_time&.id,
       live_time_id_out: right_live_time&.id,
       time_in: left_live_time&.military_time(home_time_zone),
       time_out: right_live_time&.military_time(home_time_zone),
       pacer_in: left_live_time&.with_pacer,
       pacer_out: right_live_time&.with_pacer,
       dropped_here: left_live_time&.stopped_here || right_live_time&.stopped_here,
       remarks: [left_live_time&.remarks, right_live_time&.remarks].join(' / ')}
    end
  end

  def paired_live_times
    EventLiveTimePairer.pair(event: event, live_times: live_times)
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def validate_setup
    raise ArgumentError, 'All live_times must match the provided event' unless
        live_times.all? { |lt| lt.event_id == event.id }
  end
end
