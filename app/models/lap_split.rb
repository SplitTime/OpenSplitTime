class LapSplit
  include Comparable
  attr_accessor :lap, :split
  delegate :course, to: :split

  def initialize(lap, split)
    @lap = lap
    @split = split
  end

  def <=>(other)
    [self.lap, self.split.distance_from_start] <=> [other.lap, other.split.distance_from_start]
  end

  def name
    lap && split && "#{split.base_name} Lap #{lap}"
  end

  def time_points
    lap && split.try(:id) && split.bitkeys.map { |bitkey| TimePoint.new(lap, split.id, bitkey) }
  end

  def time_point_in
    lap && split.try(:id) && split.in_bitkey && TimePoint.new(lap, split.id, split.in_bitkey)
  end

  def time_point_out
    lap && split.try(:id) && split.out_bitkey && TimePoint.new(lap, split.id, split.out_bitkey)
  end

  def distance_from_start
    (lap - 1) * course.distance + split.distance_from_start
  end
end