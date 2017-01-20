class SplitRow

  delegate :id, :name, :distance_from_start, :kind, :start?, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, :days_and_times, :time_data_statuses,
           :split_time_ids, to: :time_cluster

  # split_times should be an array having size == split.sub_splits.size,
  # with nil values where no corresponding split_time exists

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:split_times, :start_time],
                           required_alternatives: [:lap_split, :split],
                           exclusive: [:lap_split, :split, :split_times, :prior_time, :start_time],
                           deprecated: {split: :lap_split},
                           class: self.class)
    @lap_split = args[:lap_split]
    @arg_split = args[:split]
    @split_times = args[:split_times]
    @prior_time = args[:prior_time]
    @start_time = args[:start_time]
  end

  def time_cluster
    @time_cluster ||= TimeCluster.new(split, split_times, prior_time, start_time)
  end

  def split
    @split ||= arg_split || lap_split.split
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

  attr_reader :lap_split, :arg_split, :split_times, :prior_time, :start_time
end