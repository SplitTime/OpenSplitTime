class IntendedTimeCalculator
  def self.absolute_time_local(military_time:, effort:, time_point:, prior_valid_split_time: nil,
                               expected_time_from_prior: nil, lap_splits: nil, split_times: nil)
    new(
      military_time: military_time,
      effort: effort,
      time_point: time_point,
      prior_valid_split_time: prior_valid_split_time,
      expected_time_from_prior: expected_time_from_prior,
      lap_splits: lap_splits,
      split_times: split_times
    ).absolute_time_local
  end

  def initialize(military_time:, effort:, time_point:, prior_valid_split_time: nil,
                 expected_time_from_prior: nil, lap_splits: nil, split_times: nil)
    @raw_military_time = military_time
    @effort = effort
    @time_point = time_point
    validate_setup

    @lap_splits = lap_splits || effort.event.lap_splits_through(time_point.lap)
    @prior_valid_split_time = prior_valid_split_time ||
                              SplitTimeFinder.guaranteed_prior(effort: effort,
                                                               time_point: time_point,
                                                               lap_splits: @lap_splits,
                                                               split_times: split_times)
    @expected_time_from_prior = expected_time_from_prior ||
                                TimePredictor.segment_time(segment: subject_segment,
                                                           effort: effort,
                                                           lap_splits: @lap_splits,
                                                           completed_split_time: @prior_valid_split_time)
  end

  def absolute_time_local
    return nil if military_time.blank?

    if preliminary_day_and_time && (preliminary_day_and_time < threshold_day_and_time)
      preliminary_day_and_time + 1.day
    else
      preliminary_day_and_time
    end
  end

  private

  attr_reader :raw_military_time, :effort, :time_point, :lap_splits, :prior_valid_split_time,
              :expected_time_from_prior

  def military_time
    @military_time ||= raw_military_time.gsub(/[^\d:]/, "")
  end

  def preliminary_day_and_time
    expected_day_and_time && (earliest_day_and_time + days_from_earliest)
  end

  def threshold_day_and_time
    time_point_start? ? event.scheduled_start_time - 6.hours : prior_day_and_time - 3.hours
  end

  def prior_day_and_time
    @prior_day_and_time ||= prior_valid_split_time.absolute_time.in_time_zone(time_zone)
  end

  def expected_day_and_time
    expected_time_from_prior && (prior_day_and_time + expected_time_from_prior)
  end

  def earliest_day_and_time
    # Use ActiveSupport datetime parsing logic to avoid problems with DST conversion
    [prior_day_and_time.to_date.to_s, military_time].join(" ").in_time_zone(time_zone)
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
    lap_splits&.find { |lap_split| lap_split.key == prior_valid_split_time.lap_split_key }
  end

  def end_lap_split
    lap_splits&.find { |lap_split| lap_split.key == time_point.lap_split_key }
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
    raise ArgumentError, "intended_time_calculator must include military_time" unless raw_military_time
    raise ArgumentError, "intended_time_calculator must include effort" unless effort
    raise ArgumentError, "intended_time_calculator must include time_point" unless time_point

    unless military_time.is_a?(String)
      raise ArgumentError, "military time must be provided as a string; got #{military_time} (#{military_time.class})"
    end
    return unless military_time.present? && !TimeConversion.valid_military?(military_time)

    raise ArgumentError, "#{military_time} is improperly formatted for #{self.class}"
  end
end
