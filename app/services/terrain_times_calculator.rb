class TerrainTimesCalculator

  def initialize(args)
    ArgsValidator.validate(params: args, required_alternatives: [:sub_splits, :ordered_splits])
    @segments = SegmentsBuilder.segments(sub_splits: args[:sub_splits], ordered_splits: args[:ordered_splits])
  end

  def times_from_start
    @times_from_start ||= terrain_times.to_h
  end

  def segment_time(segment)
    raise ArgumentError, "segment #{segment.name} is not valid for #{self}" unless
        times_from_start[segment.end_sub_split] && times_from_start[segment.begin_sub_split]
    times_from_start[segment.end_sub_split] - times_from_start[segment.begin_sub_split]
  end

  private

  attr_accessor :segments

  def terrain_times
    segments.map { |segment| [segment.end_sub_split, segment.typical_time_by_terrain] }
  end
end