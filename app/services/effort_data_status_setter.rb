class EffortDataStatusSetter

  def self.set_data_status(args)
    setter = new(args)
    setter.set_data_status
    setter.save_changes
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :ordered_split_times, :lap_splits, :times_container],
                           class: self.class)
    @effort = args[:effort]
    @ordered_split_times = args[:ordered_split_times] || effort.ordered_split_times.to_a
    @lap_splits = args[:lap_splits] || effort.lap_splits
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
    ordered_split_times.map { |st| [st.time_point, st.data_status] }.to_h
  end

  def save_changes
    Effort.transaction do
      changed_split_times.each(&:save!)
      changed_efforts.each(&:save!)
    end
  end

  private

  attr_reader :effort, :lap_splits, :ordered_split_times, :times_container
  attr_accessor :subject_split_time, :valid_split_times, :subject_index, :prior_valid_split_time,
                :subject_begin_lap_split, :subject_end_lap_split, :subject_segment, :subject_segment_time

  def set_split_time_data_status(split_time)
    set_subject_attributes(split_time)
    subject_split_time.data_status = beyond_drop? ? 'bad' :
        time_predictor.data_status(subject_segment_time)
  end

  def set_effort_data_status
    effort.data_status = ordered_split_times.map(&:data_status_numeric)
                             .push(Effort.data_statuses['good']).compact.min
  end

  def set_subject_attributes(split_time)
    self.subject_split_time = split_time
    self.valid_split_times = ordered_split_times.select { |st| st.valid_status? | (st == subject_split_time) }
    self.subject_index = valid_split_times.index(subject_split_time)
    self.prior_valid_split_time = subject_index == 0 ? mock_start_split_time : valid_split_times[subject_index - 1]
    self.subject_begin_lap_split = indexed_lap_splits[prior_valid_split_time.lap_split_key]
    self.subject_end_lap_split = indexed_lap_splits[subject_split_time.lap_split_key]
    self.subject_segment = Segment.new(begin_point: prior_valid_split_time.time_point,
                                       end_point: subject_split_time.time_point,
                                       begin_lap_split: subject_begin_lap_split,
                                       end_lap_split: subject_end_lap_split)
    self.subject_segment_time = subject_split_time.time_from_start - prior_valid_split_time.time_from_start
  end

  def beyond_drop?
    dropped_lap_split && lap_splits.index(subject_end_lap_split) > lap_splits.index(dropped_lap_split)
  end

  def time_predictor
    TimePredictor.new(segment: subject_segment,
                      completed_split_time: prior_valid_split_time,
                      lap_splits: lap_splits,
                      times_container: times_container)
  end

  def mock_start_split_time
    @mock_start_split_time ||= SplitTime.new(time_point: ordered_split_times.first.time_point, time_from_start: 0)
  end

  def dropped_lap_split
    @dropped_lap_split ||= indexed_lap_splits[effort.dropped_lap_split_key]
  end

  def indexed_lap_splits
    @indexed_lap_splits ||= lap_splits.index_by(&:key)
  end

  def unconfirmed_split_times
    @unconfirmed_split_times ||= ordered_split_times.reject(&:confirmed?)
  end
end