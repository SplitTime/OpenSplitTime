class TimesPredictor

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :ordered_splits, :valid_split_times, :times_calculator, :calculate_by],
                           class: self.class)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.event.ordered_splits.to_a
    @valid_split_times = args[:valid_split_times] || effort.split_times.valid_status.to_a
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
    @completed_split_time ||= ordered_sub_splits.map { |sub_split| indexed_split_times[sub_split] }.compact.last
  end

  def ordered_sub_splits
    @ordered_sub_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_split_times
    @indexed_split_times ||= valid_split_times.index_by(&:sub_split)
  end

  def validate_setup

  end
end