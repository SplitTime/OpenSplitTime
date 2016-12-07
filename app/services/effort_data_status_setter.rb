class EffortDataStatusSetter

  def self.set_data_status(args)
    setter = new(args)
    setter.set_data_status
    setter.save_changes
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :ordered_split_times, :ordered_splits, :times_container],
                           class: self.class)
    @effort = args[:effort]
    @ordered_split_times = args[:ordered_split_times] || effort.ordered_split_times.to_a
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
  end

  def set_data_status
    unconfirmed_split_times.each { |split_time| set_split_time_data_status(split_time) }
    set_effort_data_status
  end

  def changed_split_times
    ordered_split_times.select(&:changed?)
  end

  def changed_efforts
    [effort].select(&:changed?)
  end

  def split_times_status_hash
    ordered_split_times.map { |st| [st.sub_split, st.data_status] }.to_h
  end

  def save_changes
    Effort.transaction do
      changed_split_times.each(&:save!)
      changed_efforts.each(&:save!)
    end
  end

  private

  attr_reader :effort, :ordered_splits, :ordered_split_times, :times_container
  attr_accessor :subject_split_time, :valid_split_times, :subject_index, :prior_valid_split_time,
                :subject_begin_split, :subject_end_split, :subject_segment, :subject_segment_time

  def set_split_time_data_status(split_time)
    set_subject_attributes(split_time)
    subject_split_time.data_status = beyond_drop? ? 'bad' :
        times_predictor.data_status(subject_segment, subject_segment_time)
  end

  def set_effort_data_status
    effort.data_status = ordered_split_times.present? ?
        [ordered_split_times.map(&:data_status_numeric).compact.min, Effort.data_statuses['good']].min : nil
  end

  def set_subject_attributes(split_time)
    self.subject_split_time = split_time
    self.valid_split_times = ordered_split_times.select { |st| st.valid_status? | (st == subject_split_time) }
    self.subject_index = valid_split_times.index(subject_split_time)
    self.prior_valid_split_time = subject_index == 0 ? mock_start_split_time : valid_split_times[subject_index - 1]
    self.subject_begin_split = indexed_splits[prior_valid_split_time.split_id]
    self.subject_end_split = indexed_splits[subject_split_time.split_id]
    self.subject_segment = Segment.new(prior_valid_split_time.sub_split, subject_split_time.sub_split, subject_begin_split, subject_end_split)
    self.subject_segment_time = subject_split_time.time_from_start - prior_valid_split_time.time_from_start
  end

  def beyond_drop?
    dropped_split && ordered_splits.index(subject_end_split) > ordered_splits.index(dropped_split)
  end

  def times_predictor
    TimesPredictor.new(working_split_time: prior_valid_split_time,
                       ordered_splits: ordered_splits,
                       times_container: times_container)
  end

  def mock_start_split_time
    @mock_start_split_time ||= SplitTime.new(sub_split: ordered_split_times.first.sub_split, time_from_start: 0)
  end

  def dropped_split
    @dropped_split ||= indexed_splits[effort.dropped_split_id]
  end

  def indexed_splits
    @indexed_splits ||= ordered_splits.index_by(&:id)
  end

  def unconfirmed_split_times
    @unconfirmed_split_times ||= ordered_split_times.reject(&:confirmed?)
  end
end