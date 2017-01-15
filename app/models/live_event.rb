class LiveEvent

  attr_reader :event
  delegate :course, :race, :simple?, to: :event

  def initialize(event)
    @event = event
    @split_times_by_effort = split_times.group_by(&:effort_id)
    @split_times_by_effort.default = []
    set_effort_time_attributes
  end

  def split_times
    @split_times ||= SplitTime.joins(:effort)
                         .select(:sub_split_bitkey, :split_id, :time_from_start)
                         .where(efforts: {event_id: event.id})
                         .ordered.to_a
  end

  def live_efforts
    @live_efforts ||= efforts.map { |effort| LiveEffort.new(effort, split_name_hash, sub_splits) }
  end

  def ordered_split_ids
    @ordered_split_ids ||= ordered_splits.map(&:id)
  end

  def efforts_started
    @efforts_started ||= efforts.select(&:started?)
  end

  def efforts_finished
    @efforts_finished ||= efforts.select(&:finished?)
  end

  def efforts_dropped
    @efforts_dropped ||= efforts.select(&:dropped?)
  end

  def efforts_in_progress
    @efforts_in_progress ||= efforts.select(&:in_progress?)
  end

  def efforts_unfinished
    @efforts_unfinished ||= efforts_started - efforts_finished
  end

  def efforts_started_count
    efforts_started.size
  end

  def efforts_finished_count
    efforts_finished.size
  end

  def efforts_dropped_count
    efforts_dropped.size
  end

  def efforts_in_progress_count
    efforts_in_progress.size
  end

  def expected_day_and_time(effort, sub_split)
    effort.start_time + expected_time_from_start(effort, sub_split)
  end

  def prior_valid_display_data(effort, sub_split)
    valid_display_data(effort, prior_valid_split_time(effort, sub_split))
  end

  def next_valid_display_data(effort, sub_split)
    valid_display_data(effort, next_valid_split_time(effort, sub_split))
  end

  private

  attr_reader :split_times_by_effort

  def set_effort_time_attributes
    efforts.each do |effort|
      effort.last_reported_split_time = split_times_by_effort[effort.id].last
      effort.event_start_time = event_start_time
      sub_split = due_next_sub_split(effort)
      if sub_split
        effort.next_expected_split_time =
            SplitTime.new(effort_id: effort.id, sub_split: sub_split,
                          time_from_start: expected_time_from_start(effort, sub_split))
      end
    end
  end

  def split_name_hash
    @split_name_hash ||= ordered_splits.map { |split| [split.id, split.base_name] }.to_h
  end

  def sub_splits
    @sub_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def efforts
    @efforts ||= event.efforts.sorted_with_finish_status
  end

  def expected_time_from_start(effort, sub_split)
    TimePredictor.segment_time(segment: Segment.new(begin_sub_split: sub_splits.first,
                                                    end_sub_split: sub_split),
                               effort: effort,
                               ordered_splits: ordered_splits,
                               completed_split_time: effort.last_reported_split_time,
                               times_container: times_container)
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end

  def times_container
    @times_container ||= SegmentTimesContainer.new(calc_model: :stats)
  end

  def due_next_sub_split(effort)
    last_reported_sub_split = effort.last_reported_split_time.sub_split
    sub_splits[sub_splits.index(last_reported_sub_split) + 1]
  end

  def prior_valid_split_time(effort, sub_split)
    subject_index = sub_splits.index(sub_split)
    return nil if subject_index == 0
    relevant_sub_splits = sub_splits[0..subject_index - 1]
    valid_split_times(effort, relevant_sub_splits).last
  end

  def next_valid_split_time(effort, sub_split)
    subject_index = sub_splits.index(sub_split)
    return nil if subject_index == sub_splits.size
    relevant_sub_splits = sub_splits[subject_index + 1..-1]
    valid_split_times(effort, relevant_sub_splits).first
  end

  def valid_split_times(effort, relevant_sub_splits)
    split_times_by_effort[effort.id]
        .select { |split_time| split_time.valid_status? && relevant_sub_splits.include?(split_time.sub_split) }
  end

  def valid_display_data(effort, split_time)
    split_time ? {split_name: split_time.split_name, day_and_time: effort.start_time + split_time.time_from_start} : {}
  end

  def event_start_time
    @event_start_time ||= event.start_time
  end
end