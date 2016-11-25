class TimesPredictor

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:effort, [:ordered_splits, :working_split_time]],
                           exclusive: [:effort, :ordered_splits, :working_split_time, :times_calculator, :calculate_by],
                           class: self.class)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @working_split_time = args[:working_split_time] || effort.valid_split_times.last
    @times_calculator = args[:times_calculator] || build_times_calculator(args[:calculate_by])
    validate_setup
  end

  def times_from_start
    @times_from_start ||= baseline_times.transform_values { |seconds| seconds * pace_factor }
  end

  def segment_time(segment)
    times_calculator.segment_time(segment) * pace_factor
  end

  private

  attr_reader :effort, :ordered_splits, :working_split_time, :times_calculator

  def build_times_calculator(calculate_by)
    calculate_by == :stats ?
        StatTimesCalculator.new(effort: effort, ordered_splits: ordered_splits, working_split_time: working_split_time) :
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