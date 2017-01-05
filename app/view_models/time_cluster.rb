class TimeCluster

  attr_reader :drop_display
  delegate :finish?, to: :split

  def initialize(split, split_times, prior_time, start_time, drop_display = false)
    @split = split
    @split_times = split_times
    @prior_time = prior_time
    @start_time = start_time
    @drop_display = drop_display
  end

  def segment_time
    @segment_time ||=
        times_from_start.compact.first - prior_time if (prior_time && (times_from_start.compact.count > 0))
  end

  def time_in_aid
    @time_in_aid ||=
        times_from_start.compact.last - times_from_start.compact.first if times_from_start.compact.count > 1
  end

  def times_from_start
    @times_from_start ||= split_times.map { |st| st.try(:time_from_start) }
  end

  def days_and_times
    @days_and_times ||= times_from_start.map { |time| time && (start_time + time.seconds) }
  end

  def time_data_statuses
    @time_data_statuses ||= split_times.map { |st| st.try(:data_status) }
  end

  private

  attr_reader :split, :split_times, :start_time, :prior_time
end