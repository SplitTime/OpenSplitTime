class SegmentTimes
  attr_reader :times, :low_bad, :low_questionable, :high_questionable, :high_bad, :mean, :std

  STAT_CALC_THRESHOLD = 8

  def initialize(segment, begin_hash = nil, end_hash = nil)
    @segment = segment
    @begin_times_hash = begin_hash || segment.begin_split.time_hash(segment.begin_bitkey)
    @end_times_hash = end_hash || segment.end_split.time_hash(segment.end_bitkey)
    @times = calculate_times(begin_times_hash, end_times_hash)
    set_mean_and_std
    set_status_limits
  end

  def status(value)
    return nil unless value
    if (value < low_bad) | (value > high_bad)
      'bad'
    elsif (value < low_questionable) | (value > high_questionable)
      'questionable'
    else
      'good'
    end
  end

  def limits
    [low_bad, low_questionable, high_questionable, high_bad]
  end

  def estimated_time
    mean || segment.typical_time_by_terrain
  end

  private

  attr_reader :segment, :begin_times_hash, :end_times_hash
  attr_writer :times, :low_bad, :low_questionable, :high_questionable, :high_bad, :mean, :std

  def calculate_times(begin_hash, end_hash)
    common_keys = begin_hash.select { |_, v| v}.keys & end_hash.select { |_, v| v}.keys
    b_hash = begin_hash.select { |key| common_keys.include?(key) }
    e_hash = end_hash.select { |key| common_keys.include?(key) }
    e_hash.merge(b_hash) { |_, x, y| x - y }
  end

  def valid_data_array
    @valid_data_array ||= reject_outliers(times.values)
  end

  def reject_outliers(array)
    baseline_median = array.median
    baseline_median ? array.select { |v| (v >= (baseline_median / 2)) && (v <= (baseline_median * 2)) } : []
  end

  def set_mean_and_std
    return unless valid_data_array.count > STAT_CALC_THRESHOLD
    self.mean = valid_data_array.mean
    self.std = valid_data_array.standard_deviation
  end

  def set_status_limits
    if segment.end_split.start?
      self.low_bad = 0
      self.low_questionable = 0
      self.high_questionable = 0
      self.high_bad = 0
    elsif segment.distance == 0 # Time within a waypoint group/aid station
      self.low_bad = 0
      self.low_questionable = 0
      self.high_questionable = 6.hours
      self.high_bad = 1.day
    else # This is a "real" segment between waypoint groups
      set_limits_by_terrain_and_stats
    end
  end

  def set_limits_by_terrain_and_stats
    self.low_bad = [segment.terrain_low_bad, stat_low_bad, 0].compact.max
    self.low_questionable = [segment.terrain_low_questionable, stat_low_questionable, 0].compact.max
    self.high_questionable = [segment.terrain_high_questionable, stat_high_questionable].compact.min
    self.high_bad = [segment.terrain_high_bad, stat_high_bad].compact.min
  end

  def stat_low_bad
    mean && mean - (4 * std)
  end

  def stat_low_questionable
    mean && mean - (3 * std)
  end

  def stat_high_questionable
    mean && mean + (4 * std)
  end

  def stat_high_bad
    mean && mean + (10 * std)
  end
end