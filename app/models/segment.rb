class Segment
  attr_accessor :begin_split, :end_split
  delegate :course, to: :begin_split
  delegate :events, :earliest_event_date, :latest_event_date, to: :end_split

# Takes one or more splits or split_ids, uses first and last element if > 2 elements

  def initialize(*splits)
    splits = splits.flatten
    @begin_split = splits[0].is_a?(Integer) ? Split.find(splits[0]) : splits[0]
    @end_split = splits[-1].is_a?(Integer) ? Split.find(splits[-1]) : splits[-1]
    raise 'Segment splits must be on same course' if @begin_split.course_id != @end_split.course_id
    raise 'Segment splits are out of order' if @begin_split.course_index > @end_split.course_index
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
    within_split? ?
        "Time in #{begin_split.base_name}" :
        [begin_split.base_name, end_split.base_name].join(' to ')
  end

  def within_split?
    begin_split == end_split
  end

  def effort_time(effort)
    within_split? ? effort.time_in_aid(begin_split) : time_between_splits(effort)
  end

  def time_between_splits(effort)
    return 0 if end_split.start?
    times = effort.split_times.where(split_id: split_ids).index_by(&:key_hash)
    end_split_time = times[end_split.sub_split_key_hashes.first]
    begin_split_time = times[begin_split.sub_split_key_hashes.last]
    (end_split_time && begin_split_time) ? (end_split_time.time_from_start - begin_split_time.time_from_start) : nil
  end

  def effort_velocity(effort)
    time = effort_time(effort)
    time == 0 ? 0 : distance / time
  end

  def distance
    end_split.distance_from_start - begin_split.distance_from_start
  end

  def vert_gain
    return nil unless end_split.vert_gain_from_start && begin_split.vert_gain_from_start
    end_split.vert_gain_from_start - begin_split.vert_gain_from_start
  end

  def vert_loss
    return nil unless end_split.vert_loss_from_start && begin_split.vert_loss_from_start
    end_split.vert_loss_from_start - begin_split.vert_loss_from_start
  end

  def typical_time_by_terrain
    (distance * DISTANCE_FACTOR) + (vert_gain ? (vert_gain * VERT_GAIN_FACTOR) : 0)
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

  private

  attr_accessor :course_ordered_split_ids

end