class EventProgressDisplay

  attr_reader :event, :progress_rows, :past_due_threshold
  delegate :name, :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object

  def initialize(event, past_due_threshold = nil)
    @event = event
    @ordered_splits = event.ordered_splits.to_a
    @split_name_hash = Hash[@ordered_splits.map { |split| [split.id, split.base_name] }]
    @bitkey_hashes = @ordered_splits.map(&:sub_split_bitkey_hashes).flatten
    @event_segment_calcs = EventSegmentCalcs.new(event)
    @efforts = event.efforts.sorted_with_finish_status
    set_effort_time_attributes
    @past_due_threshold = past_due_threshold || 60
    @progress_rows = []
    create_progress_rows
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

  def efforts_past_due_count
    past_due_progress_rows.count
  end

  def event_name
    name
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  def past_due_progress_rows
    progress_rows.select { |row| row.over_under_due > past_due_threshold.minutes }.sort_by(&:over_under_due).reverse
  end

  # private

  attr_accessor :efforts, :ordered_splits, :event_split_times, :split_name_hash, :bitkey_hashes, :event_segment_calcs

  def set_effort_time_attributes
    self.event_split_times = SplitTime.select(:sub_split_bitkey, :split_id, :time_from_start)
                                 .where(effort_id: efforts.map(&:id))
                                 .ordered
                                 .group_by(&:effort_id)
    efforts_in_progress.each do |effort|
      effort.last_reported_split_time_attr = event_split_times[effort.id].last
      bitkey_hash = due_next_bitkey_hash(effort)
      effort.start_time_attr = event_start_time + effort.start_offset
      effort.next_expected_split_time = SplitTime.new(effort_id: effort.id,
                                                      split_id: bitkey_hash.keys.first,
                                                      sub_split_bitkey: bitkey_hash.values.first,
                                                      time_from_start: expected_time_from_start(effort, bitkey_hash))
    end
  end

  def create_progress_rows
    efforts_in_progress.each do |effort|
      progress_row = EffortProgressRow.new(effort, split_name_hash, bitkey_hashes)
      progress_rows << progress_row
    end
  end

  def expected_time_from_start(effort, bitkey_hash)
    indexed_splits = ordered_splits.index_by(&:id)
    split_times = event_split_times[effort.id]
    start_split_time = split_times.first
    start_bitkey_hash = start_split_time.bitkey_hash
    return 0 if bitkey_hash == start_bitkey_hash
    subject_split_time = split_times.find { |split_time| split_time.bitkey_hash == bitkey_hash }
    prior_split_time = subject_split_time ?
        split_times[split_times.index(subject_split_time) - 1] :
        split_times.last
    completed_segment = Segment.new(start_bitkey_hash,
                                    prior_split_time.bitkey_hash,
                                    indexed_splits[start_split_time.split_id],
                                    indexed_splits[prior_split_time.split_id])
    subject_segment = Segment.new(prior_split_time.bitkey_hash,
                                  bitkey_hash,
                                  indexed_splits[prior_split_time.split_id],
                                  indexed_splits[bitkey_hash.keys.first])
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

  def due_next_bitkey_hash(effort)
    last_reported_bitkey_hash = effort.last_reported_split_time.bitkey_hash
    bitkey_hashes[bitkey_hashes.index(last_reported_bitkey_hash) + 1]
  end

  def ordered_split_ids
    ordered_splits.map(&:id)
  end

  def efforts_started
    efforts.select { |effort| event_split_times[effort.id].count > 0 }
  end

  def efforts_finished
    efforts.select { |effort| effort.final_split_id == ordered_split_ids.last }
  end

  def efforts_dropped
    efforts.select { |effort| effort.dropped_split_id.present? }
  end

  def efforts_in_progress
    efforts_started.select { |effort| effort.dropped_split_id.nil? && (effort.final_split_id != ordered_split_ids.last) }
  end

  def event_start_time
    event.start_time
  end

end