# frozen_string_literal: true

class LapSplit
  include Comparable
  attr_accessor :lap, :split
  delegate :course, :course_id, :name_extensions, :bitkeys, to: :split

  def initialize(lap, split)
    @lap = lap
    @split = split
  end

  def <=>(other)
    [self.lap, self.split.distance_from_start] <=> [other.lap, other.split.distance_from_start]
  end

  def key
    lap && split_id && LapSplitKey.new(lap, split_id)
  end

  def split_id
    split.try(:id)
  end

  def start?
    split.try(:start?) && lap == 1
  end

  def names
    bitkeys.map { |bitkey| name(bitkey) }
  end

  def names_without_laps
    bitkeys.map { |bitkey| name_without_lap(bitkey) }
  end

  def base_name
    [base_name_without_lap, lap_name].join(' ')
  end

  def base_name_without_lap
    split.try(:base_name) || '[unknown split]'
  end

  def name(bitkey = nil)
    [name_without_lap(bitkey), lap_name].join(' ')
  end

  def name_without_lap(bitkey = nil)
    (split && split.name(bitkey)) || '[unknown split]'
  end

  def lap_name
    lap ? "Lap #{lap}" : '[unknown lap]'
  end

  def time_points
    lap && split_id && split.bitkeys.map { |bitkey| TimePoint.new(lap, split_id, bitkey) }
  end

  def time_point_in
    lap && split.try(:id) && split.in_bitkey && TimePoint.new(lap, split_id, split.in_bitkey)
  end

  def time_point_out
    lap && split.try(:id) && split.out_bitkey && TimePoint.new(lap, split_id, split.out_bitkey)
  end

  def distance_from_start
    lap == 1 ? split.distance_from_start : (lap - 1) * course.distance + split.distance_from_start
  end
  
  def vert_gain_from_start
    lap == 1 ? split.vert_gain_from_start : (lap - 1) * course.vert_gain + split.vert_gain_from_start
  end

  def vert_loss_from_start
    lap == 1 ? split.vert_loss_from_start : (lap - 1) * course.vert_loss + split.vert_loss_from_start
  end
end
