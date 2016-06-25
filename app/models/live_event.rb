class LiveEvent

  attr_accessor :efforts_started, :efforts_finished, :efforts_dropped, :efforts_in_progress, :efforts_unfinished
  attr_reader :event, :ordered_split_ids, :split_times, :live_efforts
  delegate :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object
  # past_due_threshold is number of minutes (int or string)

  def initialize(event)
    @event = event
    @ordered_splits = event.ordered_splits.to_a
    @ordered_split_ids = ordered_splits.map(&:id)
    @split_name_hash = Hash[@ordered_splits.map { |split| [split.id, split.base_name] }]
    @bitkey_hashes = @ordered_splits.map(&:sub_split_bitkey_hashes).flatten
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

  def expected_day_and_time(effort, bitkey_hash)
    effort.start_time + expected_time_from_start(effort, bitkey_hash)
  end

  def prior_valid_display_data(effort, bitkey_hash)
    split_time = prior_valid_split_time(effort, bitkey_hash)
    split_time ? {split_name: split_time.split_name, day_and_time: effort.start_time + split_time.time_from_start} : {}
  end

  def next_valid_display_data(effort, bitkey_hash)
    split_time = next_valid_split_time(effort, bitkey_hash)
    split_time ? {split_name: split_time.split_name, day_and_time: effort.start_time + split_time.time_from_start} : {}
  end

  private

  attr_reader :ordered_splits, :split_name_hash, :bitkey_hashes, :event_segment_calcs, :efforts, :split_times_by_effort

  def set_effort_categories
    self.efforts_started = efforts.select { |effort| split_times_by_effort[effort.id].count > 0 }
    self.efforts_finished = efforts.select { |effort| effort.final_split_id == ordered_split_ids.last }
    self.efforts_dropped = efforts.select { |effort| effort.dropped_split_id.present? }
    self.efforts_in_progress = efforts_started - efforts_finished - efforts_dropped
    self.efforts_unfinished = efforts_started - efforts_finished
  end

  def set_effort_time_attributes
    efforts_unfinished.each do |effort|
      effort.last_reported_split_time_attr = split_times_by_effort[effort.id].last
      effort.start_time_attr = event_start_time + effort.start_offset
      bitkey_hash = due_next_bitkey_hash(effort)
      if bitkey_hash.nil?
        raise "Due next bitkey hash was not found for effort in progress #{effort.id}."
      else
        effort.next_expected_split_time = SplitTime.new(effort_id: effort.id,
                                                        split_id: bitkey_hash.keys.first,
                                                        sub_split_bitkey: bitkey_hash.values.first,
                                                        time_from_start: expected_time_from_start(effort, bitkey_hash))
      end
    end
  end

  def create_live_efforts
    efforts_unfinished.each do |effort|
      live_effort = LiveEffort.new(effort, split_name_hash, bitkey_hashes)
      live_efforts << live_effort
    end
  end

  def expected_time_from_start(effort, bitkey_hash)
    indexed_splits = ordered_splits.index_by(&:id)
    split_times = split_times_by_effort[effort.id]
    start_split_time = split_times.first
    return 0 if bitkey_hash == start_split_time.bitkey_hash
    subject_split_time = split_times.find { |split_time| split_time.bitkey_hash == bitkey_hash }
    prior_split_time = subject_split_time ?
        split_times[split_times.index(subject_split_time) - 1] :
        split_times.last
    completed_segment = Segment.new(start_split_time.bitkey_hash,
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

  def prior_valid_split_time(effort, bitkey_hash)
    subject_index = bitkey_hashes.index(bitkey_hash)
    return nil if subject_index == 0
    relevant_bitkey_hashes = bitkey_hashes[0..subject_index - 1]
    split_times_by_effort[effort.id]
        .select { |split_time| !split_time.bad? &&
        !split_time.questionable? &&
        relevant_bitkey_hashes.include?(split_time.bitkey_hash) }
        .last
  end

  def next_valid_split_time(effort, bitkey_hash)
    subject_index = bitkey_hashes.index(bitkey_hash)
    return nil if subject_index == bitkey_hashes.size
    relevant_bitkey_hashes = bitkey_hashes[subject_index + 1..-1]
    split_times_by_effort[effort.id]
        .select { |split_time| !split_time.bad? &&
        !split_time.questionable? &&
        relevant_bitkey_hashes.include?(split_time.bitkey_hash) }
        .first
  end

  def event_start_time
    event.start_time
  end

end