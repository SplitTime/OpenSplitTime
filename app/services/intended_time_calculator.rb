class IntendedTimeCalculator

  def self.day_and_time(args)
    new(args).day_and_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:military_time, :effort, :sub_split],
                           exclusive: [:military_time, :effort, :sub_split, :split_time_finder, :predictor],
                           class: self.class)
    @military_time = args[:military_time]
    @effort = args[:effort]
    @sub_split = args[:sub_split]
    @split_time_finder = args[:split_time_finder] || PriorSplitTimeFinder.new(effort: effort, sub_split: sub_split)
    @predictor = args[:predictor] || TimesPredictor.new(effort: effort, working_split_time: prior_valid_split_time)
    validate_setup
  end

  def day_and_time
    return nil unless military_time.present?
    preliminary_day_and_time && (preliminary_day_and_time < prior_day_and_time) ?
        preliminary_day_and_time + 1.day : preliminary_day_and_time
  end

  private

  attr_reader :military_time, :effort, :sub_split, :predictor, :split_time_finder

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

  def expected_time_from_prior
    @expected_time_from_prior ||= predictor.segment_time(subject_segment)
  end

  def prior_valid_split_time
    split_time_finder.guaranteed_split_time
  end

  def subject_segment
    Segment.new(begin_sub_split: prior_valid_split_time.sub_split, end_sub_split: sub_split)
  end

  def seconds_into_day
    TimeConversion.hms_to_seconds(military_time)
  end

  def validate_setup
    raise RangeError, "#{military_time} is out of range for #{self.class}" if
        seconds_into_day && ((seconds_into_day >= 1.day) | (seconds_into_day < 0))
  end
end