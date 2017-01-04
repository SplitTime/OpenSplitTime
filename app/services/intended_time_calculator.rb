class IntendedTimeCalculator

  def self.day_and_time(args)
    new(args).day_and_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:military_time, :effort, :sub_split],
                           exclusive: [:military_time, :effort, :sub_split, :prior_valid_split_time,
                                       :expected_time_from_prior, :ordered_splits, :split_times],
                           class: self.class)
    @military_time = args[:military_time]
    @effort = args[:effort]
    @sub_split = args[:sub_split]
    @ordered_splits = args[:ordered_splits]
    @prior_valid_split_time = args[:prior_valid_split_time] ||
        PriorSplitTimeFinder.guaranteed_split_time(effort: effort,
                                                   sub_split: sub_split,
                                                   ordered_splits: ordered_splits,
                                                   split_times: args[:split_times])
    @expected_time_from_prior = args[:expected_time_from_prior] ||
        TimePredictor.segment_time(segment: subject_segment,
                                   effort: effort,
                                   ordered_splits: ordered_splits,
                                   completed_split_time: prior_valid_split_time)
    validate_setup
  end

  def day_and_time
    return nil unless military_time.present?
    preliminary_day_and_time && (preliminary_day_and_time < prior_day_and_time) ?
        preliminary_day_and_time + 1.day : preliminary_day_and_time
  end

  private

  attr_reader :military_time, :effort, :sub_split, :ordered_splits, :prior_valid_split_time, :expected_time_from_prior

  def preliminary_day_and_time
    expected_day_and_time && earliest_datetime + days_from_earliest
  end

  def prior_day_and_time
    @prior_day_and_time ||= effort.start_time + prior_valid_split_time.time_from_start
  end

  def expected_day_and_time
    expected_time_from_prior && prior_day_and_time + expected_time_from_prior
  end

  def earliest_datetime
    prior_day_and_time.beginning_of_day + seconds_into_day
  end

  def days_from_earliest
    ((expected_day_and_time - earliest_datetime) / 1.day).round(0) * 1.day
  end

  def subject_segment
    Segment.new(begin_sub_split: prior_valid_split_time.sub_split,
                end_sub_split: sub_split,
                begin_split: begin_split,
                end_split: end_split)
  end

  def begin_split
    ordered_splits && ordered_splits.find { |split| split.id == prior_valid_split_time.split_id }
  end

  def end_split
    ordered_splits && ordered_splits.find { |split| split.id == sub_split.split_id }
  end

  def seconds_into_day
    TimeConversion.hms_to_seconds(military_time)
  end

  def validate_setup
    raise RangeError, "#{military_time} is out of range for #{self.class}" if seconds_into_day && ((seconds_into_day >= 1.day) | (seconds_into_day < 0))
  end
end