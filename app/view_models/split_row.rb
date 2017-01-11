class SplitRow

  attr_reader :split
  delegate :id, :name, :distance_from_start, :kind, :start?, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, :days_and_times, :time_data_statuses,
           :split_time_ids, to: :time_cluster

  # split_times should be an array having size == split.sub_splits.size,
  # with nil values where no corresponding split_time exists

  def initialize(split, split_times, prior_time, start_time)
    @split = split
    @split_times = split_times
    @prior_time = prior_time
    @start_time = start_time
    @time_cluster = TimeCluster.new(split, split_times, prior_time, start_time)
  end

  def split_id
    split.id
  end

  def data_status
    DataStatus.worst(time_data_statuses)
  end

  def pacer_in_out
    split_times.map { |st| st.try(:pacer) }
  end

  def remarks
    split_times.compact.map { |st| st.remarks }.uniq.join(' / ')
  end

  private

  attr_reader :split_times, :prior_time, :start_time, :time_cluster
end