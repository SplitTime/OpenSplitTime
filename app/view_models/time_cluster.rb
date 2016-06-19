class TimeCluster

  delegate :finish?, to: :split

  def initialize(split, split_times, prior_time, start_time)
    @split = split
    @split_times = split_times
    @prior_time = prior_time
    @start_time = start_time
  end

  def segment_time
    return nil unless (prior_time && (times_from_start.compact.count > 0))
    times_from_start.compact.first - prior_time
  end

  def time_in_aid
    return nil unless times_from_start.compact.count > 1
    times_from_start.compact.last - times_from_start.compact.first
  end

  def times_from_start
    split_times.map { |st| st ? st.time_from_start : nil }
  end

  def days_and_times
    times_from_start.map { |time| time ? start_time + time.seconds : nil }
  end

  def time_data_statuses
    split_times.map { |st| st ? st.data_status : nil }
  end

  private

  attr_reader :split, :split_times, :start_time, :prior_time

end