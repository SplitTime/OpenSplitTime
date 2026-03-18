class Segment
  attr_reader :begin_point, :end_point

  delegate :course, to: :begin_split
  delegate :events, :earliest_event_date, :most_recent_event_date, to: :end_split

  def initialize(begin_point:, end_point:, begin_lap_split: nil, end_lap_split: nil, order_control: true)
    @begin_point = begin_point
    @end_point = end_point
    @arg_begin_lap_split = begin_lap_split
    @arg_end_lap_split = end_lap_split
    @order_control = order_control
    validate_setup
  end

  def ==(other)
    (begin_point == other.begin_point) && (end_point == other.end_point)
  end

  def eql?(other)
    self == other
  end

  def hash
    [begin_point, end_point].hash
  end

  def begin_sub_split
    assumed_lap = 1
    TimePoint.new(assumed_lap, begin_point.split_id, begin_point.bitkey)
  end

  def end_sub_split
    assumed_lap = 1
    TimePoint.new(assumed_lap, end_point.split_id, end_point.bitkey)
  end

  def begin_split
    begin_lap_split.split
  end

  def end_split
    end_lap_split.split
  end

  def begin_lap_split
    @begin_lap_split ||= arg_begin_lap_split || discovered_lap_split(begin_point)
  end

  def end_lap_split
    @end_lap_split ||= arg_end_lap_split || discovered_lap_split(end_point)
  end

  def splits
    @splits ||= Split.find(split_ids).to_a
  end

  def begin_lap
    begin_point.lap
  end

  def end_lap
    end_point.lap
  end

  def name
    if in_aid?
      "Time in #{begin_split.base_name}"
    elsif zero_segment?
      begin_split.name(begin_bitkey)
    else
      [begin_split.base_name, end_split.base_name].join(" to ")
    end
  end

  def name_with_lap
    if in_aid?
      "Time in #{begin_split.base_name} Lap #{begin_lap}"
    elsif zero_segment?
      "#{begin_split.name(begin_bitkey)} Lap #{begin_lap}"
    elsif begin_lap == end_lap
      "#{begin_split.base_name} to #{end_split.base_name} Lap #{begin_lap}"
    else
      "#{begin_split.base_name} Lap #{begin_lap} to #{end_split.base_name} Lap #{end_lap}"
    end
  end

  def distance
    end_lap_split.distance_from_start - begin_lap_split.distance_from_start
  end

  def vert_gain
    end_lap_split.vert_gain_from_start.to_i - begin_lap_split.vert_gain_from_start.to_i
  end

  def vert_loss
    end_lap_split.vert_loss_from_start.to_i - begin_lap_split.vert_loss_from_start.to_i
  end

  def begin_id
    begin_point.split_id
  end

  def end_id
    end_point.split_id
  end

  def split_ids
    [begin_id, end_id]
  end

  def begin_bitkey
    begin_point.bitkey
  end

  def end_bitkey
    end_point.bitkey
  end

  def full_course?
    begin_split.start? && end_split.finish?
  end

  def zero_start?
    begin_lap_split.start? && zero_segment?
  end

  def ends_at_finish?
    end_split.finish?
  end

  def special_limits_type
    if zero_start?
      :zero_start
    elsif in_aid? || between_laps?
      :in_aid
    end
  end

  private

  attr_reader :arg_begin_lap_split, :arg_end_lap_split, :order_control

  def discovered_lap_split(time_point)
    LapSplit.new(time_point.lap, splits.find { |split| split.id == time_point.split_id })
  end

  def in_aid?
    [begin_lap, begin_id] == [end_lap, end_id] && (begin_bitkey != end_bitkey)
  end

  def between_laps?
    begin_split.finish? && end_split.start? && (end_lap - 1 == begin_lap)
  end

  def zero_segment?
    begin_point == end_point
  end

  def in_aid_bitkeys_reversed?
    in_aid? && (begin_bitkey > end_bitkey)
  end

  def splits_reversed_on_lap?
    (begin_lap == end_lap) &&
      arg_begin_lap_split && arg_end_lap_split &&
      (begin_split.distance_from_start > end_split.distance_from_start)
  end

  def laps_reversed?
    begin_lap > end_lap
  end

  def lap_splits_inconsistent?
    arg_begin_lap_split && arg_end_lap_split && (arg_begin_lap_split.course_id != arg_end_lap_split.course_id)
  end

  def validate_setup
    if lap_splits_inconsistent?
      raise ArgumentError,
            "Segment lap_splits must be on same course"
    end
    if order_control && in_aid_bitkeys_reversed?
      raise ArgumentError,
            "Segment bitkeys within the same split are out of order; " \
            "begin_split: #{begin_split.name(begin_bitkey)} Lap #{begin_lap}, " \
            "end_split: #{end_split.name(end_bitkey)} Lap #{end_lap}"
    end
    if order_control && splits_reversed_on_lap?
      raise ArgumentError,
            "Segment splits on the same lap are out of order; " \
            "begin_split: #{begin_split.name(begin_bitkey)} Lap #{begin_lap}, " \
            "end_split: #{end_split.name(end_bitkey)} Lap #{end_lap}"
    end
    return unless order_control && laps_reversed?

    raise ArgumentError,
          "Segment laps are out of order; " \
          "begin_split: #{begin_split.name(begin_bitkey)} Lap #{begin_lap}, " \
          "end_split: #{end_split.name(end_bitkey)} Lap #{end_lap}"
  end
end
