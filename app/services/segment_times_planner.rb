# frozen_string_literal: true

class SegmentTimesPlanner

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:expected_time, :event, :time_points, :similar_effort_ids],
                           exclusive: [:expected_time, :event, :time_points, :similar_effort_ids, :start_time, :times_container, :serial_segments],
                           class: self.class)
    @expected_time = args[:expected_time]
    @event = args[:event]
    @time_points = args[:time_points]
    @similar_effort_ids = args[:similar_effort_ids]
    @start_time = args[:start_time] || event.start_time
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: :focused, effort_ids: similar_effort_ids)
    @serial_segments = args[:serial_segments] ||
        SmartSegmentsBuilder.segments(event: event, time_points: time_points, times_container: times_container)
  end

  def absolute_times(round_to: 0)
    times_from_start(round_to: round_to).transform_values { |tfs| start_time + tfs }
  end

  def times_from_start(round_to: 0)
    return {} if final_segment_missing?
    @times_from_start ||= serial_segments.map.with_index do |segment, i|
      [segment.end_point, (serial_times[0..i].sum * pace_factor).round_to_nearest(round_to)]
    end.to_h
  end

  private

  attr_reader :expected_time, :event, :time_points, :similar_effort_ids, :start_time, :times_container, :serial_segments

  def serial_times
    @serial_times ||= serial_segments.map { |segment| times_container.segment_time(segment) }
  end

  def pace_factor
    @pace_factor ||= measurable_pace? ? expected_time.to_f / total_segment_time : 1
  end

  def measurable_pace?
    expected_time.positive? && total_segment_time.positive?
  end

  def total_segment_time
    serial_times.sum
  end

  def final_segment_missing?
    serial_segments.last&.end_point != time_points.last
  end
end
