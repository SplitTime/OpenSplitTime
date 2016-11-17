class SegmentCalculations
  attr_reader :times, :low_bad, :low_questionable, :high_questionable, :high_bad, :mean, :std

  STAT_CALC_THRESHOLD = 8

  def initialize(segment, begin_hash = nil, end_hash = nil)
    @segment = segment
    @begin_times_hash = begin_hash || segment.begin_split.time_hash(segment.begin_bitkey)
    @end_times_hash = end_hash || segment.end_split.time_hash(segment.end_bitkey)
    @times = calculate_times(begin_times_hash, end_times_hash)
    create_valid_data_array
    set_status_limits(segment)
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
    mean || terrain_time
  end

  private

  attr_reader :segment, :begin_times_hash, :end_times_hash
  attr_writer :times, :low_bad, :low_questionable, :high_questionable, :high_bad, :mean, :std
  attr_accessor :valid_data_array

  def calculate_times(begin_hash, end_hash)
    common_keys = begin_hash.select { |_, v| v}.keys & end_hash.select { |_, v| v}.keys
    b_hash = begin_hash.select { |key| common_keys.include?(key) }
    e_hash = end_hash.select { |key| common_keys.include?(key) }
    e_hash.merge(b_hash) { |_, x, y| x - y }
  end

  def create_valid_data_array
    baseline_median = times.median
    return [] unless baseline_median
    data_array = times.values
    data_array.keep_if { |v| (v > (baseline_median / 2)) && (v < (baseline_median * 2)) }
    self.valid_data_array = data_array
  end

  def set_status_limits(segment)
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
      set_limits_by_terrain(segment)
      set_limits_by_stats(valid_data_array)
    end
  end

  def set_limits_by_terrain(segment)
    self.low_bad = terrain_time / 5
    self.low_questionable = terrain_time / 3.5
    self.high_questionable = terrain_time * 3.5
    self.high_bad = terrain_time * 5
  end

  def set_limits_by_stats(data_array)
    return unless data_array && data_array.count > STAT_CALC_THRESHOLD
    self.mean = data_array.mean
    self.std = data_array.standard_deviation
    self.low_bad = [self.low_bad, mean - (4 * std), 0].max
    self.low_questionable = [self.low_questionable, mean - (3 * std), 0].max
    self.high_questionable = [self.high_questionable, mean + (4 * std)].min
    self.high_bad = [self.high_bad, mean + (10 * std)].min
  end

  def terrain_time
    segment.typical_time_by_terrain
  end
end