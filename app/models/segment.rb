class Segment
  attr_accessor :begin_split, :end_split

  def initialize(first_param, second_param) # Takes two splits or two split_ids in any order
    first_split = first_param.is_a?(Integer) ? Split.find(first_param) : first_param
    second_split = second_param.is_a?(Integer) ? Split.find(second_param) : second_param
    raise 'Segment splits must be on same course' if first_split.course_id != second_split.course_id
    splits = [first_split, second_split].sort_by { |split| [split.distance_from_start, split.sub_order] }
    @begin_split = splits.first
    @end_split = splits.second
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

  def name # TODO make more flexible for time in aid etc.
    begin_split.base_name == end_split.base_name ?
        [begin_split.name, end_split.name].join(' to ') :
        [begin_split.base_name, end_split.base_name].join(' to ')
  end

  def distance
    end_split.distance_from_start - begin_split.distance_from_start
  end

  def vert_gain
    return 0 unless end_split.vert_gain_from_start && begin_split.vert_gain_from_start
    end_split.vert_gain_from_start - begin_split.vert_gain_from_start
  end

  def vert_loss
    return 0 unless end_split.vert_loss_from_start && begin_split.vert_loss_from_start
    end_split.vert_loss_from_start - begin_split.vert_loss_from_start
  end

  def typical_time_by_terrain
    (distance * DISTANCE_FACTOR) + (vert_gain * VERT_GAIN_FACTOR)
  end

  def begin_id
    begin_split.id
  end

  def end_id
    end_split.id
  end

  def split_ids
    [begin_split.id, end_split.id]
  end

  def course
    begin_split.course
  end

  def times
    SegmentCalculations.new(self).times
  end

end