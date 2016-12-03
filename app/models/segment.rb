class Segment
  attr_reader :begin_sub_split, :end_sub_split
  delegate :course, to: :begin_split
  delegate :events, :earliest_event_date, :most_recent_event_date, :start?, to: :end_split

  TYPICAL_TIME_IN_AID = 15.minutes
  DISTANCE_FACTOR = 0.6 # Multiply distance in meters by this factor to approximate normal travel time on foot
  VERT_GAIN_FACTOR = 4.0 # Multiply vert_gain in meters by this factor to approximate normal travel time on foot

  def initialize(begin_sub_split, end_sub_split, begin_split = nil, end_split = nil)
    @begin_sub_split = begin_sub_split
    @end_sub_split = end_sub_split
    @arg_begin_split = begin_split
    @arg_end_split = end_split
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

  def begin_split
    @begin_split ||= arg_begin_split || splits.find { |split| split.id = begin_id }
  end

  def end_split
    @end_split ||= arg_end_split || splits.find { |split| split.id = end_id }
  end

  def splits
    @splits ||= Split.find(split_ids).to_a
  end

  def name
    in_aid? ?
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
    in_aid? ? TYPICAL_TIME_IN_AID : (distance * DISTANCE_FACTOR) + (vert_gain * VERT_GAIN_FACTOR)
  end

  def typical_time_by_stats(effort_ids = nil)
    segment_time, effort_count = SplitTime.connection.execute(typical_time_sql(effort_ids)).values.flatten
    effort_count > SegmentTimes::STATS_CALC_THRESHOLD ? segment_time : nil
  end

  def begin_id
    begin_sub_split.split_id
  end

  def end_id
    end_sub_split.split_id
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
    SegmentTimes.new(self).times
  end

  def full_course?
    begin_split.start? && end_split.finish?
  end

  def special_limits_type
    case
    when start?
      :start
    when in_aid?
      :in_aid
    else
      nil
    end
  end

  private

  attr_reader :arg_begin_split, :arg_end_split

  def in_aid?
    (begin_sub_split.split_id == end_sub_split.split_id) && (begin_bitkey != end_bitkey)
  end

  def typical_time_sql(effort_ids)
    sql = "SELECT AVG(st2.time_from_start - st1.time_from_start) AS segment_time, " +
        "COUNT(st1.time_from_start) AS effort_count " +
        "FROM (SELECT st.effort_id, st.time_from_start, st.split_id, st.sub_split_bitkey " +
        "FROM split_times st WHERE st.split_id = #{begin_id} AND st.sub_split_bitkey = #{begin_bitkey}) AS st1, " +
        "(SELECT st.effort_id, st.time_from_start, st.split_id, st.sub_split_bitkey " +
        "FROM split_times st WHERE st.split_id = #{end_id} AND st.sub_split_bitkey = #{end_bitkey}) AS st2 " +
        "WHERE st1.effort_id = st2.effort_id"
    sql += " AND st1.effort_id IN (#{effort_ids.to_a.join(',')})" if effort_ids
    sql
  end

  def validate_segment
    raise 'Segment splits must be on same course' if arg_begin_split && arg_end_split && (arg_begin_split.course_id != end_split.course_id)
    raise 'Segment sub_splits are out of order' if in_aid? && (begin_bitkey > end_bitkey)
    raise 'Segment splits are out of order' if arg_begin_split && arg_end_split && (begin_split.distance_from_start > end_split.distance_from_start)
    raise 'Segment begin sub_split does not reconcile with begin split' if arg_begin_split && (arg_begin_split.id != begin_id)
    raise 'Segment end sub_split does not reconcile with end split' if arg_end_split && (arg_end_split.id != end_id)
  end
end