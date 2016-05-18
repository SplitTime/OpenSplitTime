class Segment
  attr_accessor :begin_split, :end_split
  delegate :course, to: :begin_split
  delegate :events, :earliest_event_date, :latest_event_date, to: :end_split

# Takes one or more splits or split_ids in any order, uses first and last element
# Can take a waypoint group as a parameter

  def initialize(*splits)
    splits = splits.flatten
    first_split = splits[0].is_a?(Integer) ? Split.find(splits[0]) : splits[0]
    second_split = splits[-1].is_a?(Integer) ? Split.find(splits[-1]) : splits[-1]
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

  def name
    begin_split.base_name == end_split.base_name ?
        "Time in #{begin_split.base_name}" :
        [begin_split.base_name, end_split.base_name].join(' to ')
  end

  def effort_time(effort)
    return 0 if end_split.start?
    times = effort.split_times.where(split_id: split_ids).index_by(&:split_id)
    end_split_time = times[end_id]
    begin_split_time = times[begin_id]
    end_split_time && begin_split_time ? (end_split_time.time_from_start - begin_split_time.time_from_start) : nil
  end

  def effort_velocity(effort)
    time = effort_time(effort)
    time == 0 ? 0 : distance / time
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

  def times
    SegmentCalculations.new(self).times
  end

  def is_full_course?
    begin_split.start? && end_split.finish?
  end

end