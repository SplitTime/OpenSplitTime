class LapSplit
  include Comparable
  attr_accessor :lap, :split
  delegate :course, to: :split

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

  def distance_from_start
    (lap - 1) * course.distance + split.distance_from_start
  end
end