class PriorSplitTimeFinder

  def self.split_time(args)
    new(args).split_time
  end

  def self.guaranteed_split_time(args)
    new(args).guaranteed_split_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :time_point,
                           required_alternatives: [:effort, [:lap_splits, :split_times]],
                           class: self.class)
    @time_point = args[:time_point]
    @effort = args[:effort]
    @lap_splits = args[:lap_splits]
    @split_times = args[:split_times] || effort.ordered_split_times.to_a
    validate_setup
  end

  def split_time
    @split_time ||= relevant_time_points.map { |time_point| indexed_split_times[time_point] }.compact.last
  end

  def guaranteed_split_time
    @guaranteed_split_time ||= split_time || mock_start_split_time
  end

  private

  attr_reader :effort, :time_point, :lap_splits, :split_times

  def relevant_time_points
    time_point_index.zero? ? [] : ordered_time_points[0..time_point_index - 1]
  end

  def mock_start_split_time
    SplitTime.new(time_point: ordered_time_points.first, time_from_start: 0)
  end

  def time_point_index
    ordered_time_points.index(time_point)
  end

  def ordered_time_points
    @ordered_time_points ||= lap_splits.map(&:time_points).flatten
  end

  def indexed_split_times
    @indexed_split_times ||= valid_split_times.index_by(&:time_point)
  end

  def valid_split_times
    split_times.select(&:valid_status?)
  end

  def validate_setup
    raise ArgumentError, 'time_point is not contained in the provided splits' unless
        ordered_time_points.include?(time_point)
    raise ArgumentError, 'split_times do not all belong to the same effort' unless
        split_times.map(&:effort_id).uniq.size < 2
    raise ArgumentError, 'split_times do not relate to the provided effort' if
        effort && split_times.any? { |st| st.effort_id != effort.id }
  end
end