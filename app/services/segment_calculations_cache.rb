class SegmentCalculationsCache
  attr_reader :time_hashes

  def initialize(event, hash = {})
    @segment_calcs = hash
    @time_hashes = event.time_hashes
  end

  def []=(k, v)
    @segment_calcs[k] = v
  end

  def [](k)
    @segment_calcs[k]
  end

  def fetch_calculations(segment)
    self[segment] ||= SegmentCalculations.new(segment, time_hashes[segment.begin_id], time_hashes[segment.end_id])
  end

  def get_data_status(segment, segment_time)
    fetch_calculations(segment).status(segment_time)
  end

  def limits(segment)
    fetch_calculations(segment).limits
  end

  def times(segment)
    fetch_calculations(segment).times
  end

  def mean(segment)
    fetch_calculations(segment).mean
  end

  def std(segment)
    fetch_calculations(segment).std
  end

  def stats(segment)
    fetch_calculations(segment).stats
  end

end