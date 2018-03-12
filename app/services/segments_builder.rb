# frozen_string_literal: true

class SegmentsBuilder

  def self.segments(args)
    new(args).segments
  end

  def self.segments_with_zero_start(args)
    new(args).segments_with_zero_start
  end

  # If splits are not provided, the resulting segments will be "thin" (without lap_splits)
  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :time_points,
                           exclusive: [:time_points, :splits],
                           class: self.class)
    @time_points = args[:time_points]
    @splits = args[:splits] || []
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
end
