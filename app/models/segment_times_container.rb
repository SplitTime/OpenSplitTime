class SegmentTimesContainer

  def initialize(args)
    ArgsValidator.validate(params: args, required_alternatives: [:effort_ids, :efforts, :split_times], class: self.class)
    @effort_ids = args[:effort_ids] || (args[:efforts] && args[:efforts].map(&:id)) || []
    @split_times = args[:split_times] || SplitTime.valid_status.basic_components.where(effort_id: effort_ids)
    @segment_times = args[:segment_times] || {}
  end

  def []=(segment, times)
    segment_times[segment] = times
  end

  def [](segment)
    segment_times[segment] ||=
        SegmentTimes.new(segment, time_hashes[segment.begin_sub_split], time_hashes[segment.end_sub_split])
  end

  def data_status(segment, segment_time)
    self[segment].status(segment_time)
  end

  def limits(segment)
    self[segment].limits
  end

  def times(segment)
    self[segment].times
  end

  def mean(segment)
    self[segment].mean
  end

  def std(segment)
    self[segment].std
  end

  def estimated_time(segment)
    self[segment].estimated_time
  end

  private

  attr_reader :effort_ids, :split_times, :segment_times

  def time_hashes
    @time_hashes ||=
        complete_hash.map { |sub_split, split_times| [sub_split, id_time_hash(split_times)] }.to_h
  end

  def complete_hash
    @complete_hash ||= split_times.group_by(&:sub_split)
  end

  def id_time_hash(split_times)
    split_times.map { |split_time| [split_time.effort_id, split_time.time_from_start] }.to_h
  end
end