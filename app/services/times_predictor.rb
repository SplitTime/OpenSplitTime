class TimesPredictor

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :ordered_splits, :valid_split_times, :times_calculator, :calculate_by],
                           class: self.class)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @valid_split_times = args[:valid_split_times] || effort.valid_split_times.to_a
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

  attr_reader :effort, :ordered_splits, :valid_split_times, :times_calculator

  def build_times_calculator(calculate_by)
    calculate_by == :stats ?
        StatTimesCalculator.new(effort: effort, ordered_splits: ordered_splits, valid_split_times: valid_split_times) :
        TerrainTimesCalculator.new(ordered_splits: ordered_splits)
  end

  def baseline_times
    times_calculator.times_from_start
  end

  def pace_factor
    measurable_pace? ? completed_time / pace_baseline : 1
  end

  def measurable_pace?
    completed_split_time && completed_time > 0
  end

  def pace_baseline
    baseline_times[completed_sub_split]
  end

  def completed_time
    completed_split_time.time_from_start
  end

  def completed_sub_split
    completed_split_time.sub_split
  end

  def completed_split_time
    @completed_split_time ||= finish_split_time || prior_split_time_finder.split_time
  end

  def prior_split_time_finder
    @prior_split_time_finder ||= PriorSplitTimeFinder.new(effort: effort,
                                                          sub_split: finish_sub_split,
                                                          split_times: valid_split_times,
                                                          ordered_splits: ordered_splits)
  end

  def finish_split_time
    valid_split_times.find { |split_time| split_time.sub_split == finish_sub_split }
  end

  def finish_sub_split
    @finish_sub_split ||= ordered_splits.last.sub_splits.first
  end

  def validate_setup

  end
end