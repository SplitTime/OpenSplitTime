class SegmentCalculationsCache

  def initialize(hash = {})
    @data = hash
  end

  def []=(k, v)
    @data[k] = v
  end

  def [](k)
    @data[k]
  end

  def fetch_calculations(segment)
    self[segment] ||= SegmentCalculations.new(segment, self.fetch_time_hash(segment.begin_split), self.fetch_time_hash(segment.end_split))
  end

  def fetch_time_hash(split)
    self[split] ||= split.time_hash
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