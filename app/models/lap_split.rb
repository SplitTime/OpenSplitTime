class LapSplit
  include Comparable
  attr_accessor :lap, :split

  def initialize(lap, split)
    @lap = lap
    @split = split
  end

  def name
    lap && split && "#{split.base_name} Lap #{lap}"
  end

  def time_point
    lap && split && split.id && TimePoint.new(lap, split.id)
  end

  def <=>(other)
    [self.lap, self.split.distance_from_start] <=> [other.lap, other.split.distance_from_start]
  end
end