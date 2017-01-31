class LiveEvent

  attr_reader :event
  delegate :course, :race, :simple?, to: :event

  def initialize(event)
    @event = event
    set_effort_time_attributes
  end

  def split_times
    SplitTime.joins(:effort)
        .select(:effort_id, :lap, :split_id, :sub_split_bitkey, :time_from_start)
        .where(efforts: {event_id: event.id})
        .ordered
  end

  def split_times_by_effort
    return @split_times_by_effort if defined?(@split_times_by_effort)
    @split_times_by_effort = split_times.group_by(&:effort_id)
    @split_times_by_effort.default = []
    @split_times_by_effort
  end

  def live_efforts
    @live_efforts ||= efforts.map { |effort| LiveEffort.new(effort, split_name_hash, time_points) }
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

  def expected_day_and_time(effort, time_point)
    effort.start_time + expected_time_from_start(effort, time_point)
  end

  def prior_valid_display_data(effort, time_point)
    valid_display_data(effort, prior_valid_split_time(effort, time_point))
  end

  def next_valid_display_data(effort, time_point)
    valid_display_data(effort, next_valid_split_time(effort, time_point))
  end

  private

  attr_reader :split_times_by_effort

  def set_effort_time_attributes
    efforts.each do |effort|
      effort.last_reported_split_time = split_times_by_effort[effort.id].last
      time_point = due_next_time_point(effort)
      if time_point
        effort.next_expected_split_time =
            SplitTime.new(effort_id: effort.id, time_point: time_point,
                          time_from_start: expected_time_from_start(effort, time_point))
      end
    end
  end

  def split_name_hash
    @split_name_hash ||= ordered_splits.map { |split| [split.id, split.base_name] }.to_h
  end

  def time_points
    @time_points ||= lap_splits.map(&:time_points).flatten
  end

  def efforts
    @efforts ||= event.efforts.sorted_with_finish_status
  end

  def expected_time_from_start(effort, time_point)
    TimePredictor.segment_time(segment: Segment.new(begin_point: time_points.first,
                                                    end_point: time_point),
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

  def due_next_time_point(effort)
    last_reported_time_point = effort.last_reported_split_time.time_point
    time_points[time_points.index(last_reported_time_point) + 1]
  end

  def prior_valid_split_time(effort, time_point)
    subject_index = time_points.index(time_point)
    return nil if subject_index == 0
    relevant_time_points = time_points[0..subject_index - 1]
    valid_split_times(effort, relevant_time_points).last
  end

  def next_valid_split_time(effort, time_point)
    subject_index = time_points.index(time_point)
    return nil if subject_index == time_points.size
    relevant_time_points = time_points[subject_index + 1..-1]
    valid_split_times(effort, relevant_time_points).first
  end

  def valid_split_times(effort, relevant_time_points)
    split_times_by_effort[effort.id]
        .select { |split_time| split_time.valid_status? && relevant_time_points.include?(split_time.time_point) }
  end

  def valid_display_data(effort, split_time)
    split_time ? {split_name: split_time.split_name, day_and_time: effort.start_time + split_time.time_from_start} : {}
  end
end