class TimesPredictor

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:effort, [:ordered_splits, :working_split_time]],
                           exclusive: [:effort, :ordered_splits, :working_split_time, :times_calculator, :similar_efforts],
                           class: self.class)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @working_split_time = args[:working_split_time] || effort.valid_split_times.last
    @times_calculator = args[:times_calculator] || build_times_calculator(args[:similar_efforts])
    validate_setup
  end

  # Note: #times_from_start will return all times regardless of segment completion.
  # To ensure greatest accuracy, call #segment_time when you need the most accurate
  # times for a particular segment.

  def times_from_start
    @times_from_start ||= baseline_times.transform_values { |seconds| seconds * pace_factor }
  end

  def segment_time(segment)
    times_calculator.segment_time(segment) * pace_factor
  end

  def limits(segment)
    times_calculator.limits(segment).map { |limit| limit * pace_factor }
  end

  def data_status(segment, time_from_start)
    DataStatus.determine(limits(segment), time_from_start)
  end

  private

  attr_reader :effort, :ordered_splits, :working_split_time, :times_calculator

  def build_times_calculator(similar_efforts)
    similar_efforts && (similar_efforts.count > SegmentTimes::STAT_CALC_THRESHOLD) ?
        StatTimesCalculator.new(ordered_splits: ordered_splits, efforts: similar_efforts) :
        TerrainTimesCalculator.new(ordered_splits: ordered_splits)
  end

  def baseline_times
    times_calculator.times_from_start
  end

  def pace_factor
    measurable_pace? ? working_time / baseline_times[working_split_time.sub_split] : 1
  end

  def measurable_pace?
    working_split_time && working_time > 0
  end

  def working_time
    working_split_time.time_from_start
  end

  def validate_setup
    raise ArgumentError, 'working_split_time is not associated with the splits' if working_split_time &&
        ordered_splits.map(&:sub_splits).flatten.exclude?(working_split_time.sub_split)
  end
end