class LiveEvent

  attr_accessor :efforts_started, :efforts_finished, :efforts_dropped, :efforts_in_progress, :efforts_unfinished
  attr_reader :event, :ordered_split_ids, :split_times, :live_efforts
  delegate :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object

  def initialize(event)
    @event = event
    @ordered_splits = event.ordered_splits.to_a
    @ordered_split_ids = ordered_splits.map(&:id)
    @split_name_hash = Hash[@ordered_splits.map { |split| [split.id, split.base_name] }]
    @sub_splits = @ordered_splits.map(&:sub_splits).flatten
    @event_segment_calcs = EventSegmentCalcs.new(event)
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

  attr_reader :ordered_splits, :split_name_hash, :sub_splits, :event_segment_calcs, :efforts, :split_times_by_effort

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
      unless sub_split.nil?
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

  def expected_time_from_start(effort, sub_split)
    indexed_splits = ordered_splits.index_by(&:id)
    split_times = split_times_by_effort[effort.id]
    start_split_time = split_times.first
    return 0 if sub_split == start_split_time.sub_split
    subject_split_time = split_times.find { |split_time| split_time.sub_split == sub_split }
    prior_split_time = subject_split_time ?
        split_times[split_times.index(subject_split_time) - 1] :
        split_times.last
    completed_segment = Segment.new(start_split_time.sub_split,
                                    prior_split_time.sub_split,
                                    indexed_splits[start_split_time.split_id],
                                    indexed_splits[prior_split_time.split_id])
    subject_segment = Segment.new(prior_split_time.sub_split,
                                  sub_split,
                                  indexed_splits[prior_split_time.split_id],
                                  indexed_splits[sub_split.split_id])
    completed_segment_calcs = event_segment_calcs.fetch_calculations(completed_segment)
    subject_segment_calcs = event_segment_calcs.fetch_calculations(subject_segment)
    pace_baseline = completed_segment_calcs.mean ?
        completed_segment_calcs.mean :
        completed_segment.typical_time_by_terrain
    pace_factor = pace_baseline == 0 ? 1 :
        prior_split_time.time_from_start / pace_baseline
    subject_segment_calcs.mean ?
        (prior_split_time.time_from_start + (subject_segment_calcs.mean * pace_factor)) :
        (prior_split_time.time_from_start + (subject_segment.typical_time_by_terrain * pace_factor))
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