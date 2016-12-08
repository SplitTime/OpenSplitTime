class LiveEvent

  attr_reader :event, :ordered_split_ids, :split_times, :live_efforts,
              :efforts_started, :efforts_finished, :efforts_dropped, :efforts_in_progress, :efforts_unfinished
  delegate :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object

  def initialize(event)
    @event = event
    @ordered_splits = event.ordered_splits.to_a
    @ordered_split_ids = ordered_splits.map(&:id)
    @split_name_hash = Hash[@ordered_splits.map { |split| [split.id, split.base_name] }]
    @sub_splits = @ordered_splits.map(&:sub_splits).flatten
    @efforts = event.efforts.sorted_with_finish_status
    @split_times = SplitTime.joins(:effort)
                       .select(:sub_split_bitkey, :split_id, :time_from_start)
                       .where(efforts: {event_id: event.id})
                       .ordered.to_a
    @split_times_by_effort = split_times.group_by(&:effort_id)
    @live_efforts = []
    set_effort_categories
    set_effort_time_attributes
    create_live_efforts
  end

  def efforts_started_count
    efforts_started.count
  end

  def efforts_finished_count
    efforts_finished.count
  end

  def efforts_dropped_count
    efforts_dropped.count
  end

  def efforts_in_progress_count
    efforts_in_progress.count
  end

  def expected_day_and_time(effort, sub_split)
    effort.start_time + expected_time_from_start(effort, sub_split)
  end

  def prior_valid_display_data(effort, sub_split)
    split_time = prior_valid_split_time(effort, sub_split)
    split_time ? {split_name: split_time.split_name, day_and_time: effort.start_time + split_time.time_from_start} : {}
  end

  def next_valid_display_data(effort, sub_split)
    split_time = next_valid_split_time(effort, sub_split)
    split_time ? {split_name: split_time.split_name, day_and_time: effort.start_time + split_time.time_from_start} : {}
  end

  private

  attr_reader :ordered_splits, :split_name_hash, :sub_splits, :efforts, :split_times_by_effort
  attr_writer :efforts_started, :efforts_finished, :efforts_dropped, :efforts_in_progress, :efforts_unfinished

  def set_effort_categories
    self.efforts_started = efforts.select { |effort| split_times_by_effort[effort.id].count > 0 }
    self.efforts_finished = efforts.select { |effort| effort.final_split_id == ordered_split_ids.last }
    self.efforts_dropped = efforts.select { |effort| effort.dropped_split_id.present? }
    self.efforts_in_progress = efforts_started - efforts_finished - efforts_dropped
    self.efforts_unfinished = efforts_started - efforts_finished
  end

  def set_effort_time_attributes
    efforts.each do |effort|
      effort.last_reported_split_time = split_times_by_effort[effort.id].last
      effort.start_time = event_start_time + effort.start_offset
      sub_split = due_next_sub_split(effort)
      if sub_split
        effort.next_expected_split_time = SplitTime.new(effort_id: effort.id,
                                                        sub_split: sub_split,
                                                        time_from_start: expected_time_from_start(effort, sub_split))
      end
    end
  end

  def create_live_efforts
    efforts.each do |effort|
      live_effort = LiveEffort.new(effort, split_name_hash, sub_splits)
      live_efforts << live_effort
    end
  end

  def times_container
    @times_container ||= SegmentTimesContainer.new(calc_model: :stats)
  end

  def expected_time_from_start(effort, sub_split)
    TimesPredictor.new(effort: effort,
                       ordered_splits: ordered_splits,
                       working_split_time: effort.last_reported_split_time,
                       times_container: times_container)
        .time_from_start(sub_split)
  end

  def due_next_sub_split(effort)
    last_reported_sub_split = effort.last_reported_split_time.sub_split
    sub_splits[sub_splits.index(last_reported_sub_split) + 1]
  end

  def prior_valid_split_time(effort, sub_split)
    subject_index = sub_splits.index(sub_split)
    return nil if subject_index == 0
    relevant_sub_splits = sub_splits[0..subject_index - 1]
    split_times_by_effort[effort.id]
        .select { |split_time| !split_time.bad? &&
        !split_time.questionable? &&
        relevant_sub_splits.include?(split_time.sub_split) }
        .last
  end

  def next_valid_split_time(effort, sub_split)
    subject_index = sub_splits.index(sub_split)
    return nil if subject_index == sub_splits.size
    relevant_sub_splits = sub_splits[subject_index + 1..-1]
    split_times_by_effort[effort.id]
        .select { |split_time| !split_time.bad? &&
        !split_time.questionable? &&
        relevant_sub_splits.include?(split_time.sub_split) }
        .first
  end

  def event_start_time
    event.start_time
  end
end