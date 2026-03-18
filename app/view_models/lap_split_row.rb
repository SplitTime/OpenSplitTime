class LapSplitRow
  attr_reader :not_in_event

  delegate :distance_from_start, :lap, :split, :key, :time_points, to: :lap_split
  delegate :id, :kind, :start?, :intermediate?, :finish?, :base_name, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, :absolute_times_local, :time_data_statuses,
           :split_time_ids, :stopped_here_flags, :stopped_here?, to: :time_cluster

  # split_times should be an array having size == lap_split.time_points.size,
  # with nil values where no corresponding split_time exists

  def initialize(lap_split:, split_times:, show_laps: nil, in_times_only: nil, not_in_event: nil)
    @lap_split = lap_split
    @split_times = split_times
    @show_laps = show_laps
    @in_times_only = in_times_only
    @not_in_event = not_in_event
    validate_setup
  end

  def name
    show_laps ? name_with_lap : name_without_lap
  end

  def time_cluster
    @time_cluster ||= TimeCluster.new(split_times_data: visible_split_times, finish: finish?,
                                      show_indicator_for_stop: show_indicator_for_stop?)
  end

  def split_id
    split.id
  end

  def data_status
    DataStatus.worst(time_data_statuses)
  end

  def remarks
    split_times.compact.map(&:remarks).uniq.join(" / ")
  end

  def done?
    stopped_here? || finish?
  end

  def show_indicator_for_stop?
    !finish? || show_laps
  end

  def empty?
    split_times.none?(&:absolute_time?)
  end

  private

  attr_reader :lap_split, :split_times, :show_laps, :in_times_only

  def name_without_lap
    in_times_only ? split.base_name : split.name
  end

  def name_with_lap
    in_times_only ? lap_split.base_name : lap_split.name
  end

  def visible_split_times
    in_times_only ? split_times.select(&:in_sub_split?) : split_times
  end

  def validate_setup
    raise ArgumentError, "lap_split_row must include lap_split" unless lap_split
    raise ArgumentError, "lap_split_row must include split_times" unless split_times

    return if split_times.size == split.bitkeys.size

    raise ArgumentError,
          "split_time objects must be provided for each sub_split (fill with an empty object if needed)"
  end
end
