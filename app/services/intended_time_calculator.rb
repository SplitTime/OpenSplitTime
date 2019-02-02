# frozen_string_literal: true

class IntendedTimeCalculator

  def self.absolute_time_local(args)
    new(args).absolute_time_local
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:military_time, :effort, :time_point],
                           exclusive: [:military_time, :effort, :time_point, :prior_valid_split_time,
                                       :expected_time_from_prior, :lap_splits, :split_times],
                           class: self.class)
    @military_time = args[:military_time].gsub(/[^\d:]/, '')
    @effort = args[:effort]
    @time_point = args[:time_point]
    @lap_splits = args[:lap_splits] || effort.event.lap_splits_through(time_point.lap)
    @prior_valid_split_time = args[:prior_valid_split_time] ||
        SplitTimeFinder.guaranteed_prior(effort: effort,
                                         time_point: time_point,
                                         lap_splits: lap_splits,
                                         split_times: args[:split_times])
    @expected_time_from_prior = args[:expected_time_from_prior] ||
        TimePredictor.segment_time(segment: subject_segment,
                                   effort: effort,
                                   lap_splits: lap_splits,
                                   completed_split_time: prior_valid_split_time)
    validate_setup
  end

  def absolute_time_local
    return nil unless military_time.present?
    preliminary_day_and_time && (preliminary_day_and_time < threshold_day_and_time) ?
        preliminary_day_and_time + 1.day : preliminary_day_and_time
  end

  private

  attr_reader :military_time, :effort, :time_point, :lap_splits, :prior_valid_split_time, :expected_time_from_prior

  def preliminary_day_and_time
    expected_day_and_time && earliest_day_and_time + days_from_earliest
  end

  def threshold_day_and_time
    time_point_start? ? event.start_time - 6.hours : prior_day_and_time - 3.hours
  end

  def prior_day_and_time
    @prior_day_and_time ||= prior_valid_split_time.absolute_time.in_time_zone(time_zone)
  end

  def expected_day_and_time
    expected_time_from_prior && prior_day_and_time + expected_time_from_prior
  end

  def earliest_day_and_time
    # Use ActiveSupport datetime parsing logic to avoid problems with DST conversion
    [prior_day_and_time.to_date.to_s, military_time].join(' ').in_time_zone(time_zone)
  end

  def days_from_earliest
    ((expected_day_and_time - earliest_day_and_time) / 1.day).round(0) * 1.day
  end

  def subject_segment
    Segment.new(begin_point: prior_valid_split_time.time_point,
                end_point: time_point,
                begin_lap_split: begin_lap_split,
                end_lap_split: end_lap_split)
  end

  def begin_lap_split
    lap_splits && lap_splits.find { |lap_split| lap_split.key == prior_valid_split_time.lap_split_key }
  end

  def end_lap_split
    lap_splits && lap_splits.find { |lap_split| lap_split.key == time_point.lap_split_key }
  end

  def time_point_start?
    lap_splits.present? && (time_point == lap_splits.first.time_point_in)
  end

  def event
    @event ||= effort.event
  end

  def time_zone
    event.home_time_zone
  end

  def validate_setup
    raise ArgumentError, "military time must be provided as a string; got #{military_time} (#{military_time.class})" unless military_time.is_a?(String)
    raise ArgumentError, "#{military_time} is improperly formatted for #{self.class}" if military_time.present? && !TimeConversion.valid_military?(military_time)
  end
end
