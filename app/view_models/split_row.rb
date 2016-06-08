class SplitRow

  delegate :name, :distance_from_start, :kind, :start?, :intermediate?, :finish?, to: :split
  delegate :time_in_aid, :times_from_start, :days_and_times, :time_data_statuses, to: :time_cluster

  # split_times should be an array having size == split.sub_split_bitkey_hashes.size,
  # with nil values where no corresponding split_time exists

  def initialize(split, split_times, prior_time = nil, start_time = nil)
    @split = split
    @split_times = split_times
    @prior_time = prior_time
    @start_time = start_time
    @time_cluster = TimeCluster.new(split, split_times, start_time)
  end

  def split_id
    split.id
  end

  def segment_time
    return nil unless (prior_time && (times_from_start.compact.count > 0))
    times_from_start.compact.first - prior_time
  end

  def data_status
    DataStatus.worst(time_data_statuses)
  end

  # private

  attr_reader :split, :split_times, :prior_time, :start_time, :time_cluster

end