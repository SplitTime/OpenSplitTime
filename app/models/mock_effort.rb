class MockEffort

  attr_accessor :relevant_events, :relevant_efforts
  attr_reader :course, :expected_time, :start_time, :split_rows

  MAX_EVENTS = 5

  def initialize(event, expected_time, start_time)
    @event = event
    @course = @event.course
    @expected_time = expected_time
    @start_time = start_time
    set_relevant_resources
    @split_times = create_plan_split_times
    @split_rows = create_split_rows
  end

  def total_segment_time
    split_rows.sum { |row| row.segment_time }
  end

  def total_time_in_aid
    split_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  def relevant_efforts_count
    relevant_efforts.count
  end

  def event_years_analyzed
    relevant_events.pluck(:start_time).sort.map(&:year)
  end

  private

  attr_accessor :splits
  attr_reader :event, :split_times

  def set_relevant_resources
    self.relevant_events = course.events.recent(MAX_EVENTS)
    self.relevant_events[-1] = event unless relevant_events.include?(event)
    self.relevant_efforts = course.relevant_efforts(expected_time, relevant_events).to_a
    self.splits = event.ordered_splits.to_a
  end

  def create_plan_split_times # Temporary split_time objects to assist in constructing the view
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

  def calculate_plan_times # Hash of {{split.id => bitkey} => plan_time_from_start}
    average_time_hash = {}
    splits.each do |split|
      split.sub_split_bitkeys.each do |bitkey|
        sub_split_average = split.average_time(bitkey, relevant_efforts)
        average_time_hash[{split.id => bitkey}] = sub_split_average
      end
    end
    normalize_time_data(average_time_hash, expected_time)
  end

  def normalize_time_data(time_data, expected_time)
    average_finish_time = time_data[{splits.last.id => 1}]
    return time_data unless average_finish_time
    factor = expected_time / average_finish_time
    time_data.each { |k, v| time_data[k] = v * factor }
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
    split.sub_split_bitkey_hashes.collect { |key_hash| split_times[key_hash] }
  end

end