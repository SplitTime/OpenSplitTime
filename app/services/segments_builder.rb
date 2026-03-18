class SegmentsBuilder
  def self.segments(time_points:, splits: nil)
    new(time_points: time_points, splits: splits).segments
  end

  def self.segments_with_zero_start(time_points:, splits: nil)
    new(time_points: time_points, splits: splits).segments_with_zero_start
  end

  # If splits are not provided, the resulting segments will be "thin" (without lap_splits)
  def initialize(time_points:, splits: nil)
    @time_points = time_points
    @splits = Array.wrap(splits)
    validate_setup
  end

  def segments
    time_points.each_cons(2).map do |begin_point, end_point|
      Segment.new(begin_point: begin_point,
                  end_point: end_point,
                  begin_lap_split: lap_split_from_time_point(begin_point),
                  end_lap_split: lap_split_from_time_point(end_point))
    end
  end

  def segments_with_zero_start
    segments.present? ? segments.unshift(zero_start_segment) : []
  end

  private

  attr_reader :time_points, :splits

  def indexed_splits
    @indexed_splits ||= splits.index_by(&:id)
  end

  def start_time_point
    time_points.first
  end

  def lap_split_from_time_point(time_point)
    split = indexed_splits[time_point.split_id]
    split && LapSplit.new(time_point.lap, split)
  end

  def start_lap_split
    lap_split_from_time_point(start_time_point)
  end

  def zero_start_segment
    Segment.new(begin_point: start_time_point,
                end_point: start_time_point,
                begin_lap_split: start_lap_split,
                end_lap_split: start_lap_split)
  end

  def validate_setup
    raise ArgumentError, "segments_builder must include time_points" unless time_points
  end
end
