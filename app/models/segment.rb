class Segment
  attr_reader :begin_sub_split, :end_sub_split
  delegate :course, to: :begin_split
  delegate :events, :earliest_event_date, :most_recent_event_date, :start?, to: :end_split

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:begin_sub_split, :end_sub_split],
                           exclusive: [:begin_sub_split, :end_sub_split, :begin_split, :end_split, :order_control],
                           class: self.class)
    @begin_sub_split = args[:begin_sub_split]
    @end_sub_split = args[:end_sub_split]
    @arg_begin_split = args[:begin_split]
    @arg_end_split = args[:end_split]
    @order_control = args[:order_control].nil? ? true : args[:order_control]
    validate_setup
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
    @begin_split ||= arg_begin_split || splits.find { |split| split.id == begin_id }
  end

  def end_split
    @end_split ||= arg_end_split || splits.find { |split| split.id == end_id }
  end

  def splits
    @splits ||= Split.find(split_ids).to_a
  end

  def name
    case
    when in_aid?
      "Time in #{begin_split.base_name}"
    when zero_segment?
      "#{begin_split.name(begin_bitkey)}"
    else
      [begin_split.base_name, end_split.base_name].join(' to ')
    end
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

  attr_reader :arg_begin_split, :arg_end_split, :order_control

  def in_aid?
    (begin_sub_split.split_id == end_sub_split.split_id) && (begin_bitkey != end_bitkey)
  end

  def zero_segment?
    begin_sub_split == end_sub_split
  end

  def validate_setup
    raise 'Segment splits must be on same course' if arg_begin_split && arg_end_split && (arg_begin_split.course_id != end_split.course_id)
    raise 'Segment sub_splits are out of order' if order_control && in_aid? && (begin_bitkey > end_bitkey)
    raise 'Segment splits are out of order' if order_control && arg_begin_split && arg_end_split &&
        (begin_split.distance_from_start > end_split.distance_from_start)
    raise 'Segment begin sub_split does not reconcile with begin split' if arg_begin_split && (arg_begin_split.id != begin_id)
    raise 'Segment end sub_split does not reconcile with end split' if arg_end_split && (arg_end_split.id != end_id)
  end
end