class SegmentTimesContainer

  def initialize(args)
    ArgsValidator.validate(params: args, 
                           required_alternatives: [:efforts, :effort_ids],
                           exclusive: [:efforts, :effort_ids, :segment_stats_times], 
                           class: self.class)
    @efforts = args[:efforts] || Effort.find(args[:effort_ids])
    @segment_stats_times = args[:segment_stats_times] || {}
  end

  def []=(segment, segment_stats_time)
    segment_stats_times[segment] = segment_stats_time
  end

  def [](segment)
    segment_stats_times[segment] ||= SegmentStatsTime.new(segment: segment, efforts: efforts)
  end

  def mean(segment)
    self[segment].mean
  end

  def data_status(segment, seconds)
    self[segment].status(seconds)
  end

  def limits(segment)
    self[segment].limits
  end

  private

  attr_reader :effort_ids, :split_times, :segment_stats_times
end