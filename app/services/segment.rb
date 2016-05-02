class Segment
  attr_accessor :begin_split, :end_split

  def initialize(begin_split, end_split)
    @begin_split = begin_split
    @end_split = end_split
  end

  def identify
    [begin_split, end_split]
  end

  def ==(other)
    (begin_split == other.begin_split) && (end_split == other.end_split)
  end

  def eql?(other)
    self == other
  end

  def hash
    [begin_split, end_split].hash
  end

  def distance
    end_split.distance_from_start - begin_split.distance_from_start
  end

  def vert_gain
    return 0 unless end_split.vert_gain_from_start && begin_split.vert_gain_from_start
    end_split.vert_gain_from_start - begin_split.vert_gain_from_start
  end

  def typical_time_by_terrain
    (distance * 0.6) + (vert_gain * 4.0)
  end

end