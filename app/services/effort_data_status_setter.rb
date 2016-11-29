class EffortDataStatusSetter

  def self.set_data_status(args)
    new(args).set_data_status
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: :effort)
    @effort = args[:effort]
    @split_times = args[:split_times] || effort.ordered_split_times.to_a
    @times_calculator = args[:times_calculator] ||
        StatTimesCalculator.new(ordered_splits: ordered_splits, efforts: similar_efforts)
  end

  def set_data_status
    split_times.each do |split_time|
      self.subject_split_time = split_time
      set_split_time_data_status
    end
    set_effort_data_status
  end

  def changed_split_times
    split_times.select(&:changed?)
  end

  def changed_efforts
    [effort].select(&:changed?)
  end

  def save_changes
    Effort.transaction do
      changed_split_times.each(&:save!)
      changed_efforts.each(&:save!)
    end
  end

  private

  attr_reader :effort, :split_times, :times_calculator
  attr_accessor :subject_split_time

  def ordered_splits
    @ordered_splits ||= effort.ordered_splits.to_a
  end

  def similar_efforts
    SimilarEffortFinder.new(sub_split: last_valid_split_time.sub_split,
                            time_from_start: last_valid_split_time.time_from_start).efforts
  end

  def set_split_time_data_status
    return if subject_split_time.confirmed?
    subject_split_time.data_status = times_predictor.data_status(subject_segment, subject_split_time.time_from_start)
  end

  def set_effort_data_status
    effort.data_status = split_times.map(&:data_status_numeric).compact.min
  end

  def times_predictor
    TimesPredictor.new(working_split_time: split_time_for_prediction, ordered_splits: ordered_splits, times_calculator: times_calculator)
  end

  def split_time_for_prediction
    PriorSplitTimeFinder.new(sub_split: subject_split_time.sub_split,
                             ordered_splits: ordered_splits,
                             split_times: split_times).split_time
  end

  def subject_segment
    Segment.new(split_time_for_prediction.sub_split, subject_split_time.sub_split)
  end

  def last_valid_split_time
    valid_split_times.last
  end

  def valid_split_times
    split_times.select(&:valid_status?)
  end
end