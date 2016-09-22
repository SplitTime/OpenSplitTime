class MockEffort

  attr_accessor :relevant_events, :relevant_efforts
  attr_reader :course, :expected_time, :start_time, :split_rows

  MAX_EVENTS = 5

  def initialize(event, expected_time, start_time, splits = nil)
    @event = event
    @course = @event.course
    @expected_time = expected_time
    @start_time = start_time
    set_relevant_resources
    @splits = splits || course.ordered_splits.to_a
    @indexed_split_times = create_plan_split_times
    @split_rows = create_split_rows
  end

  def total_segment_time
    split_rows.sum { |row| row.segment_time }
  end

  def total_time_in_aid
    split_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  def finish_time_from_start
    split_rows.last.times_from_start.first
  end

  def relevant_efforts_count
    relevant_efforts.count
  end

  def event_years_analyzed
    relevant_events.pluck(:start_time).sort.map(&:year).uniq
  end

  private

  attr_accessor :splits, :relevant_split_times
  attr_reader :event, :indexed_split_times

  def set_relevant_resources
    self.relevant_events = course.events.where(concealed: false).recent(MAX_EVENTS)
    self.relevant_events << event unless relevant_events.include?(event)
    self.relevant_efforts = course.relevant_efforts(expected_time, relevant_events).to_a
  end

  def create_plan_split_times # Temporary split_time objects to assist in constructing the mock effort
    plan_times = calculate_plan_times
    result = []
    splits.each do |split|
      split.sub_split_bitkeys.each do |key|
        split_time = SplitTime.new(split: split, sub_split_bitkey: key, time_from_start: plan_times[{split.id => key}])
        result << split_time
      end
    end
    result.index_by(&:bitkey_hash)
  end

  def calculate_plan_times # Hash of {{split.id => bitkey} => mock_time_from_start}
    average_time_hash = {}
    self.relevant_split_times = SplitTime.where(effort: relevant_efforts).group_by(&:bitkey_hash)
    splits.each do |split|
      split.sub_split_bitkeys.each do |bitkey|
        bitkey_hash = {split.id => bitkey}
        average_time_hash[bitkey_hash] = relevant_split_times[bitkey_hash] ?
            relevant_split_times[bitkey_hash].map(&:time_from_start).mean : nil
      end
    end
    normalize_time_data(average_time_hash, expected_time)
  end

  def normalize_time_data(time_data, expected_time)
    average_finish_time = relevant_split_times[finish_bitkey_hash] ?
        relevant_split_times[finish_bitkey_hash].map(&:time_from_start).mean : nil
    return time_data unless average_finish_time
    factor = expected_time / average_finish_time
    time_data.each { |k, v| time_data[k] = v ? v * factor : nil }
  end

  def create_split_rows
    prior_time = 0
    result = []
    splits.each do |split|
      split_row = SplitRow.new(split, related_split_times(split), prior_time, start_time)
      result << split_row
      prior_time = split_row.times_from_start.last
    end
    result
  end

  def related_split_times(split)
    split.sub_split_bitkey_hashes.collect { |key_hash| indexed_split_times[key_hash] }
  end

  def finish_bitkey_hash
    event.ordered_splits.last.bitkey_hash_in
  end

end