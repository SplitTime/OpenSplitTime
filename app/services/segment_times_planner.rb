class SegmentTimesPlanner

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:expected_time, :ordered_splits],
                           exclusive: [:expected_time, :ordered_splits, :calc_model,
                                       :similar_effort_ids, :times_container],
                           class: self.class)
    @expected_time = args[:expected_time]
    @ordered_splits = args[:ordered_splits]
    @calc_model = args[:calc_model] || :terrain
    @similar_effort_ids = args[:similar_effort_ids]
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
  end

  def segment_times(round_to: 0)
    @segment_times ||=
        indexed_serial_times
            .transform_values { |seconds| (seconds * pace_factor).round_to_nearest(round_to) } if complete_time_set?
  end

  def times_from_start(round_to: 0)
    @times_from_start ||=
        serial_segments.map
            .with_index { |segment, i| [segment.end_sub_split,
                                        (serial_times[0..i].sum * pace_factor).round_to_nearest(round_to)] }
            .to_h if complete_time_set?
  end

  private

  attr_reader :expected_time, :ordered_splits, :calc_model, :similar_effort_ids, :times_container

  def complete_time_set?
    serial_times.present? && serial_times.exclude?(nil)
  end

  def indexed_serial_times
    @indexed_serial_times ||= serial_segments.zip(serial_times).to_h
  end

  def serial_times
    @serial_times ||= serial_segments.map { |segment| times_container.segment_time(segment) }
  end

  def serial_segments
    @serial_segments ||= SegmentsBuilder.segments_with_zero_start(ordered_splits: ordered_splits)
  end

  def pace_factor
    @pace_factor ||= expected_time / total_segment_time
  end

  def total_segment_time
    indexed_serial_times.sum
  end
end