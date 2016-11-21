class IntendedTimeCalculator

  def self.day_and_time(args)
    new(args).day_and_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:military_time, :effort, :sub_split], class: self.class)
    @military_time = args[:military_time]
    @effort = args[:effort]
    @sub_split = args[:sub_split]
    @predictor = args[:predictor] || TimesPredictor.new(effort: effort)
    validate_setup
  end

  def day_and_time
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
    @expected_time_from_start ||= predictor.times_from_start[sub_split]
  end

  def start_time
    @start_time ||= effort.start_time
  end

  def seconds_into_day
    TimeConversion.hms_to_seconds(military_time)
  end

  def validate_setup
    raise RangeError, "#{military_time} is out of range for #{self.class}" if
        (seconds_into_day >= 1.day) | (seconds_into_day < 0)
  end
end