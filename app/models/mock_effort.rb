class MockEffort

  attr_reader :course, :expected_time, :start_time

  def initialize(args)
    ParamValidator.validate(params: args, required: [:course, :expected_time, :start_time], class: self.class)
    @course = args[:course]
    @expected_time = args[:expected_time]
    @start_time = args[:start_time]
    @splits = args[:splits] || course.ordered_splits.to_a
    @finder = args[:effort_finder] ||
        SimilarEffortFinder.new(sub_split: finish_sub_split, time_from_start: expected_time, split: finish_split)
    validate_setup
  end

  def indexed_split_times
    @indexed_split_times ||= create_plan_split_times
  end

  def split_rows
    @split_rows ||= create_split_rows
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

  def relevant_events
    @relevant_events ||= finder.events
  end

  def relevant_efforts
    @relevant_efforts ||= finder.efforts
  end


  private

  attr_accessor :splits, :relevant_split_times

  def create_plan_split_times # Temporary split_time objects to assist in constructing the mock effort
    plan_times = calculate_plan_times
    plan_split_times = []
    splits.each do |split|
      split.bitkeys.each do |key|
        split_time = SplitTime.new(split: split, sub_split_bitkey: key, time_from_start: plan_times[{split.id => key}])
        plan_split_times << split_time
      end
    end
    plan_split_times.index_by(&:sub_split)
  end

  def calculate_plan_times # Hash of {sub_split => mock_time_from_start}
    average_time_hash = {}
    self.relevant_split_times = SplitTime.where(effort: relevant_efforts).group_by(&:sub_split)
    splits.each do |split|
      split.sub_split_bitkeys.each do |bitkey|
        sub_split = {split.id => bitkey}
        average_time_hash[sub_split] = relevant_split_times[sub_split] &&
            relevant_split_times[sub_split].map(&:time_from_start).mean
      end
    end
    normalize_time_data(average_time_hash, expected_time)
  end

  def normalize_time_data(time_data, expected_time)
    average_finish_time = relevant_split_times[finish_sub_split] ?
        relevant_split_times[finish_sub_split].map(&:time_from_start).mean : nil
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
    split.sub_splits.map { |key_hash| indexed_split_times[key_hash] }
  end

  def finish_split
    splits.last
  end

  def finish_sub_split
    finish_split.sub_split_in
  end

  def validate_setup
    raise ArgumentError, 'one or more provided splits are not contained within the provided course' unless splits.all? { |split| split.course_id == course.id }
  end
end