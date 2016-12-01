class SegmentTimes
  attr_reader :times

  STATS_CALC_THRESHOLD = 8

  def initialize(segment, begin_hash = nil, end_hash = nil)
    @segment = segment
    @begin_times_hash = begin_hash || segment.begin_split.time_hash(segment.begin_bitkey)
    @end_times_hash = end_hash || segment.end_split.time_hash(segment.end_bitkey)
    @times = calculate_times(begin_times_hash, end_times_hash)
  end

  def status(value)
    DataStatus.determine(limits, value)
  end

  def limits
    DataStatus.limits(estimated_time, limits_type)
  end

  def mean
    stats_threshold_exceeded? ? valid_data_array.mean : nil
  end

  def estimated_time
    mean || segment.typical_time_by_terrain
  end

  private

  attr_reader :segment, :begin_times_hash, :end_times_hash
  attr_writer :times, :mean

  def calculate_times(begin_hash, end_hash)
    common_keys = begin_hash.select { |_, v| v }.keys & end_hash.select { |_, v| v }.keys
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

  def limits_type
    segment.special_limits_type || (stats_threshold_exceeded? ? :stats : :terrain)
  end

  def stats_threshold_exceeded?
    valid_data_array.count > STATS_CALC_THRESHOLD
  end
end