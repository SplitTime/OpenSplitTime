class IntendedTimeCalculator

  def self.day_and_time(args)
    new(args).day_and_time
  end

  def initialize(args)
    ParamValidator.validate(params: args, required: [:military_time, :effort], class: self.class)
    @military_time = args[:military_time]
    @effort = args[:effort]
    @sub_split = args[:sub_split]
    @predictor = args[:predictor] || TimePredictor.new(effort: effort, sub_split: sub_split)
  end

  def day_and_time
    return nil if seconds_into_day >= 1.day
    expected_day_and_time && earliest_datetime + days_from_earliest
  end

  private

  attr_reader :military_time, :effort, :sub_split, :predictor

  def expected_day_and_time
    expected_time_from_start && start_time + expected_time_from_start
  end

  def earliest_datetime
    start_time.beginning_of_day + seconds_into_day
  end

  def days_from_earliest
    (((earliest_datetime - expected_day_and_time) * -1) / 1.day).round(0) * 1.day
  end

  def expected_time_from_start
    @expected_time_from_start ||= predictor.predicted_time
  end

  def start_time
    @start_time ||= effort.start_time
  end

  def seconds_into_day
    TimeConversion.hms_to_seconds(military_time)
  end
end