# frozen_string_literal: true

class SegmentTimesPlanner

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:expected_time, :lap_splits],
                           exclusive: [:expected_time, :lap_splits, :calc_model,
                                       :similar_effort_ids, :times_container, :serial_segments],
                           class: self.class)
    @expected_time = args[:expected_time]
    @lap_splits = args[:lap_splits]
    @calc_model = args[:calc_model] || :terrain
    @similar_effort_ids = args[:similar_effort_ids]
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
    @serial_segments = args[:serial_segments] ||
        SegmentsBuilder.segments_with_zero_start(time_points: time_points, splits: splits)
  end

  def segment_times(round_to: 0)
    @segment_times ||=
        indexed_serial_times
            .transform_values { |seconds| (seconds * pace_factor).round_to_nearest(round_to) } if complete_time_set?
  end

  def times_from_start(round_to: 0)
    @times_from_start ||=
        serial_segments.map
            .with_index { |segment, i| [segment.end_point,
                                        (serial_times[0..i].sum * pace_factor).round_to_nearest(round_to)] }
            .to_h if complete_time_set?
  end

  private

  attr_reader :expected_time, :lap_splits, :calc_model, :similar_effort_ids, :times_container, :serial_segments

  def complete_time_set?
    serial_times.present? && serial_times.all?(&:present?)
  end

  def indexed_serial_times
    @indexed_serial_times ||= serial_segments.zip(serial_times).to_h
  end

  def serial_times
    @serial_times ||= serial_segments.map { |segment| times_container.segment_time(segment) }
  end

  def pace_factor
    @pace_factor ||= expected_time.to_f / total_segment_time
  end

  def total_segment_time
    indexed_serial_times.values.compact.sum
  end

  def time_points
    lap_splits.flat_map(&:time_points).select do |tp|
      SplitTime.where(lap: tp.lap, split_id: tp.split_id, bitkey: tp.bitkey).size > SegmentTimeCalculator::STATS_CALC_THRESHOLD
    end
  end

  def splits
    lap_splits.map(&:split)
  end
end
