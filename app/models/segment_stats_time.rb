class SegmentStatsTime

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:segment, :efforts],
                           exclusive: [:segment, :efforts],
                           class: self.class)
    @segment = args[:segment]
    @efforts = args[:efforts]
  end

  def mean
    @mean ||= segment.typical_time_by_stats(efforts)
  end

  def status(seconds)
    DataStatus.determine(limits, seconds)
  end

  def limits
    DataStatus.limits(mean, :stats)
  end

  private

  attr_reader :segment, :efforts
end