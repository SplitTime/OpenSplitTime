class SplitRow

  delegate :name, :distance_from_start, :kind, :start?, :intermediate?, :finish?, to: :split

  # split_times should be an array having size == split.sub_split_key_hashes.size,
  # with nil values where no corresponding split_time exists

  def initialize(split, split_times, prior_time = nil, start_time = nil)
    @split = split
    @split_times = split_times
    @prior_time = prior_time
    @start_time = start_time
  end

  def split_id
    split.id
  end

  def segment_time
    return nil unless (prior_time && (times_from_start.compact.count > 0))
    times_from_start.first - prior_time
  end

  def time_in_aid
    return nil unless times_from_start.compact.count > 1
    times_from_start.last - times_from_start.first
  end

  def times_from_start
    split_times.map { |st| st ? st.time_from_start : nil }
  end

  def days_and_times
    start_time ?
        times_from_start.map { |time| time ? start_time + time : nil } :
        split_times.map { |st| st ? st.day_and_time : nil }
  end

  def time_data_statuses
    split_times.map { |st| st ? st.data_status : nil }
  end

  def data_status
    DataStatus.worst(time_data_statuses)
  end

  # private

  attr_accessor :split, :split_times, :prior_time, :start_time

end