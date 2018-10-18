# frozen_string_literal: true

class LapSplitRow

  delegate :distance_from_start, :lap, :split, :key, :time_points, to: :lap_split
  delegate :id, :kind, :start?, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, :days_and_times, :time_data_statuses,
           :split_time_ids, :stopped_here_flags, :stopped_here?, to: :time_cluster

  # split_times should be an array having size == lap_split.time_points.size,
  # with nil values where no corresponding split_time exists

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:lap_split, :split_times],
                           exclusive: [:lap_split, :split_times, :show_laps],
                           class: self.class)
    @lap_split = args[:lap_split]
    @split_times = args[:split_times]
    @show_laps = args[:show_laps]
    validate_setup
  end

  def name
    show_laps ? name_with_lap : name_without_lap
  end

  def time_cluster
    @time_cluster ||= TimeCluster.new(finish: split.finish?, split_times_data: split_times)
  end

  def split_id
    split.id
  end

  def data_status
    DataStatus.worst(time_data_statuses)
  end

  def remarks
    split_times.compact.map(&:remarks).uniq.join(' / ')
  end

  def done?
    stopped_here? || finish?
  end

  private

  attr_reader :lap_split, :split_times, :show_laps

  def name_without_lap
    split.name
  end

  def name_with_lap
    lap_split.name
  end

  def validate_setup
    raise ArgumentError, 'split_time objects must be provided for each sub_split (fill with an empty object if needed)' unless split_times.size == split.bitkeys.size
  end
end
