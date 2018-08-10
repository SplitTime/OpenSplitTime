# frozen_string_literal: true

class SegmentTimesPlanner

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:expected_time, :event, :laps, :similar_effort_ids],
                           exclusive: [:expected_time, :event, :laps, :similar_effort_ids, :times_container, :serial_segments],
                           class: self.class)
    @expected_time = args[:expected_time]
    @event = args[:event]
    @laps = args[:laps]
    @similar_effort_ids = args[:similar_effort_ids]
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
    @serial_segments = args[:serial_segments] ||
        SmartSegmentsBuilder.segments(event: event, laps: laps, expected_time: expected_time,
                                      similar_effort_ids: similar_effort_ids, times_container: times_container)
  end

  def times_from_start(round_to: 0)
    @times_from_start ||= serial_segments.map.with_index do |segment, i|
      [segment.end_point, (serial_times[0..i].sum * pace_factor).round_to_nearest(round_to)]
    end.to_h
  end

  private

  attr_reader :expected_time, :event, :laps, :calc_model, :similar_effort_ids, :times_container, :serial_segments

  def serial_times
    @serial_times ||= serial_segments.map { |segment| times_container.segment_time(segment) }
  end

  def pace_factor
    @pace_factor ||= expected_time.to_f / total_segment_time
  end

  def total_segment_time
    serial_times.sum
  end
end
