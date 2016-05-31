class SegmentCalculations
  attr_accessor :times, :valid_data_array, :low_bad, :low_q, :high_q, :high_bad, :mean, :std

  def initialize(segment, begin_times_hash = nil, end_times_hash = nil)
    begin_times_hash ||= segment.begin_split.time_hash(segment.begin_split.sub_split_bitkeys.last)
    end_times_hash ||= segment.end_split.time_hash(segment.end_split.sub_split_bitkeys.first)
    @times = calculate_times(begin_times_hash, end_times_hash)
    create_valid_data_array
    set_status_limits(segment)
  end

  def status(value)
    return nil unless value
    if (value < low_bad) | (value > high_bad)
      :bad
    elsif (value < low_q) | (value > high_q)
      :questionable
    else
      :good
    end
  end

  def limits
    [low_bad, low_q, high_q, high_bad]
  end

  def stats
    "normalized mean: #{mean}, normalized std: #{std}"
  end

  private

  def calculate_times(begin_hash, end_hash)
    b = begin_hash.dup
    e = end_hash.dup
    b.keep_if { |k, _| e.keys.include?(k) }
    e.keep_if { |k, _| b.keys.include?(k) }
    e.merge(b) { |_, x, y| x - y }
  end

  def create_valid_data_array
    baseline_median = times.median
    return [] unless baseline_median
    data_array = times.values
    data_array.keep_if { |v| (v > (baseline_median / 2)) && (v < (baseline_median * 2)) }
    @valid_data_array = data_array
  end

  def set_status_limits(segment)
    if segment.end_split.start?
      self.low_bad = 0
      self.low_q = 0
      self.high_q = 0
      self.high_bad = 0
    elsif segment.distance == 0 # Time within a waypoint group/aid station
      self.low_bad = 0
      self.low_q = 0
      self.high_q = 6.hours
      self.high_bad = 1.day
    else # This is a "real" segment between waypoint groups
      set_limits_by_terrain(segment)
      set_limits_by_stats(valid_data_array)
    end
  end

  def set_limits_by_terrain(segment)
    typical_time = segment.typical_time_by_terrain
    self.low_bad = typical_time / 5
    self.low_q = typical_time / 3.5
    self.high_q = typical_time * 3.5
    self.high_bad = typical_time * 5
  end

  def set_limits_by_stats(data_array)
    return if data_array.count < 3
    self.mean = data_array.mean
    self.std = data_array.standard_deviation
    self.low_bad = [self.low_bad, mean - (4 * std), 0].max
    self.low_q = [self.low_q, mean - (3 * std), 0].max
    self.high_q = [self.high_q, mean + (4 * std)].min
    self.high_bad = [self.high_bad, mean + (10 * std)].min

  end

end