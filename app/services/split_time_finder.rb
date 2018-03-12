# frozen_string_literal: true

class SplitTimeFinder

  def self.prior(args)
    new(args).prior
  end

  def self.guaranteed_prior(args)
    new(args).guaranteed_prior
  end

  def self.next(args)
    new(args).next
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :time_point,
                           required_alternatives: [:effort, [:lap_splits, :split_times]],
                           exclusive: [:time_point, :effort, :lap_splits, :split_times, :valid],
                           class: self.class)
    @time_point = args[:time_point]
    @effort = args[:effort]
    @lap_splits = args[:lap_splits] || effort.event.lap_splits_through(time_point.lap)
    @split_times = args[:split_times] || effort.ordered_split_times
    @valid = args[:valid].nil? ? true : args[:valid]
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
    SplitTime.new(effort: effort, time_point: ordered_time_points.first, time_from_start: 0)
  end

  def ordered_time_points
    @ordered_time_points ||= lap_splits.flat_map(&:time_points)
  end

  def indexed_split_times
    @indexed_split_times ||= scoped_split_times.index_by(&:time_point)
  end

  def scoped_split_times
    valid ? split_times.select { |st| st.time_from_start && st.valid_status? } : split_times
  end

  def validate_setup
    raise ArgumentError, 'time_point is not contained in the provided lap_splits' unless
        ordered_time_points.include?(time_point)
    raise ArgumentError, 'split_times do not all belong to the same effort' unless
        split_times.map(&:effort_id).uniq.size < 2
    raise ArgumentError, 'split_times do not relate to the provided effort' if
        effort && split_times.any? { |st| st.effort_id != effort.id }
  end
end
