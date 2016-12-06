class EffortDataStatusSetter

  def self.set_data_status(args)
    setter = new(args)
    setter.set_data_status
    setter.save_changes
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :split_times, :times_predictor, :times_container],
                           class: self.class)
    @effort = args[:effort]
    @split_times = args[:split_times] || effort.ordered_split_times.to_a
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :terrain)
  end

  def set_data_status
    split_times.each { |split_time| set_split_time_data_status(split_time) }
    set_effort_data_status
  end

  def changed_split_times
    split_times.select(&:changed?)
  end

  def changed_efforts
    [effort].select(&:changed?)
  end

  def split_times_status_hash
    split_times.map { |st| [st.sub_split, st.data_status] }.to_h
  end

  def save_changes
    Effort.transaction do
      changed_split_times.each(&:save!)
      changed_efforts.each(&:save!)
    end
  end

  private

  attr_reader :effort, :split_times, :times_container
  attr_accessor :subject_split_time

  def ordered_splits
    @ordered_splits ||= effort.ordered_splits.to_a
  end

  def set_split_time_data_status(split_time)
    self.subject_split_time = split_time
    return if subject_split_time.confirmed?
    subject_split_time.data_status = beyond_drop? ? 'bad' :
        times_predictor.data_status(subject_segment, subject_segment_time)
  end

  def set_effort_data_status
    effort.data_status = split_times.present? &&
        [split_times.map(&:data_status_numeric).compact.min, Effort.data_statuses['good']].min
  end

  def times_predictor
    TimesPredictor.new(working_split_time: split_time_for_prediction,
                       ordered_splits: ordered_splits,
                       times_container: times_container)
  end

  def split_time_for_prediction
    PriorSplitTimeFinder
        .new(sub_split: subject_split_time.sub_split, ordered_splits: ordered_splits, split_times: split_times)
        .guaranteed_split_time
  end

  def subject_segment
    Segment.new(split_time_for_prediction.sub_split, subject_split_time.sub_split, subject_begin_split, subject_end_split)
  end

  def beyond_drop?
    dropped_split && ordered_splits.index(subject_end_split) > ordered_splits.index(dropped_split)
  end

  def dropped_split
    ordered_splits.find { |split| split.id == effort.dropped_split_id }
  end

  def subject_begin_split
    ordered_splits.find { |split| split.id == split_time_for_prediction.split_id }
  end

  def subject_end_split
    ordered_splits.find { |split| split.id == subject_split_time.split_id }
  end

  def subject_segment_time
    subject_split_time.time_from_start - split_time_for_prediction.time_from_start
  end

  def last_valid_split_time
    valid_split_times.last || mock_start_split_time
  end

  def mock_start_split_time
    SplitTime.new(sub_split: split_times.first.sub_split, time_from_start: 0)
  end

  def valid_split_times
    split_times.select(&:valid_status?)
  end
end