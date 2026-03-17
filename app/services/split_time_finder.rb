class SplitTimeFinder
  def self.prior(time_point:, effort: nil, lap_splits: nil, split_times: nil, valid: nil)
    new(time_point: time_point, effort: effort, lap_splits: lap_splits, split_times: split_times, valid: valid).prior
  end

  def self.guaranteed_prior(time_point:, effort: nil, lap_splits: nil, split_times: nil, valid: nil)
    new(time_point: time_point, effort: effort, lap_splits: lap_splits, split_times: split_times,
        valid: valid).guaranteed_prior
  end

  def self.next(time_point:, effort: nil, lap_splits: nil, split_times: nil, valid: nil)
    new(time_point: time_point, effort: effort, lap_splits: lap_splits, split_times: split_times, valid: valid).next
  end

  def initialize(time_point:, effort: nil, lap_splits: nil, split_times: nil, valid: nil)
    raise ArgumentError, "split_time_finder must include time_point" unless time_point

    # Validate required_alternatives: must have either effort OR (lap_splits AND split_times)
    unless effort || (lap_splits && split_times)
      raise ArgumentError, "split_time_finder must include either effort or both lap_splits and split_times"
    end

    @time_point = time_point
    @effort = effort
    @lap_splits = lap_splits || effort.event.lap_splits_through(time_point.lap)
    @split_times = split_times || effort.ordered_split_times
    @valid = valid.nil? || valid
    validate_setup
  end

  def prior
    @prior ||= prior_time_points.map { |time_point| indexed_split_times[time_point] }.compact.last
  end

  def guaranteed_prior
    @guaranteed_prior ||= prior || mock_start_split_time
  end

  def next
    @next ||= later_time_points.map { |time_point| indexed_split_times[time_point] }.compact.first
  end

  private

  attr_reader :effort, :time_point, :lap_splits, :split_times, :valid

  def prior_time_points
    ordered_time_points.elements_before(time_point)
  end

  def later_time_points
    ordered_time_points.elements_after(time_point)
  end

  def mock_start_split_time
    SplitTime.new(effort: effort, time_point: ordered_time_points.first, absolute_time: effort_start_time)
  end

  def effort_start_time
    effort.calculated_start_time
  end

  def ordered_time_points
    @ordered_time_points ||= lap_splits.flat_map(&:time_points)
  end

  def indexed_split_times
    @indexed_split_times ||= scoped_split_times.index_by(&:time_point)
  end

  def scoped_split_times
    valid ? split_times.select { |st| st.absolute_time && st.valid_status? } : split_times
  end

  def validate_setup
    raise ArgumentError, "time_point is not contained in the provided lap_splits" unless
        ordered_time_points.include?(time_point)
    raise ArgumentError, "split_times do not all belong to the same effort" unless
        split_times.map(&:effort_id).uniq.size < 2
    raise ArgumentError, "split_times do not relate to the provided effort" if
        effort && split_times.any? { |st| st.effort_id != effort.id }
  end
end
