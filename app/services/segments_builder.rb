class SegmentsBuilder

  def self.segments(args)
    new(args).segments
  end

  def self.segments_with_zero_start(args)
    new(args).segments_with_zero_start
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :lap_splits,
                           exclusive: :lap_splits,
                           class: self.class)
    @lap_splits = args[:lap_splits] || Split.where(id: args[:sub_splits].map(&:split_id)).ordered.to_a
  end

  def segments
    time_points.each_cons(2).map do |begin_point, end_point|
      Segment.new(begin_point: begin_point,
                  end_point: end_point,
                  begin_lap_split: indexed_lap_splits[begin_point.lap_split_key],
                  end_lap_split: indexed_lap_splits[end_point.lap_split_key])
    end
  end

  def segments_with_zero_start
    segments.present? ? segments.unshift(zero_start_segment) : []
  end

  private

  attr_accessor :lap_splits

  def time_points
    @time_points ||= lap_splits.map(&:time_points).flatten
  end

  def indexed_lap_splits
    @indexed_lap_splits ||= lap_splits.index_by(&:key)
  end

  def start_lap_split
    @start_lap_split ||= lap_splits.first
  end

  def zero_start_segment
    Segment.new(begin_point: start_lap_split.time_point_in,
                end_point: start_lap_split.time_point_in,
                begin_lap_split: start_lap_split,
                end_lap_split: start_lap_split)
  end
end