class Segment
  attr_reader :begin_split, :end_split, :begin_sub_split, :end_sub_split
  delegate :course, to: :begin_split
  delegate :events, :earliest_event_date, :most_recent_event_date, to: :end_split

  def initialize(begin_sub_split, end_sub_split, begin_split = nil, end_split = nil)
    @begin_sub_split = begin_sub_split
    @end_sub_split = end_sub_split
    @begin_split = begin_split || Split.find(begin_sub_split.split_id)
    @end_split = end_split || Split.find(end_sub_split.split_id)
    validate_segment
  end

  def ==(other)
    (begin_sub_split == other.begin_sub_split) && (end_sub_split == other.end_sub_split)
  end

  def eql?(other)
    self == other
  end

  def hash
    [begin_sub_split, end_sub_split].hash
  end

  def name
    within_split? ?
        "Time in #{begin_split.base_name}" :
        [begin_split.base_name, end_split.base_name].join(' to ')
  end

  def distance
    end_split.distance_from_start - begin_split.distance_from_start
  end

  def vert_gain
    end_split.vert_gain_from_start.to_i - begin_split.vert_gain_from_start.to_i
  end

  def vert_loss
    end_split.vert_loss_from_start.to_i - begin_split.vert_loss_from_start.to_i
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
    [begin_id, end_id]
  end

  def begin_bitkey
    begin_sub_split.bitkey
  end

  def end_bitkey
    end_sub_split.bitkey
  end

  def times
    SegmentCalculations.new(self).times
  end

  def full_course?
    begin_split.start? && end_split.finish?
  end

  private

  def validate_segment
    raise 'Segment splits must be on same course' if begin_split.course_id != end_split.course_id
    raise 'Segment sub_splits are out of order' if within_split? && (begin_bitkey > end_bitkey)
    raise 'Segment splits are out of order' if begin_split.distance_from_start > end_split.distance_from_start
    raise 'Segment begin sub_split does not reconcile with begin split' if begin_sub_split.split_id != begin_id
    raise 'Segment end sub_split does not reconcile with end split' if end_sub_split.split_id != end_id
  end

  def within_split?
    begin_split == end_split
  end
end