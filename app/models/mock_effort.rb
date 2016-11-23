class MockEffort

  attr_reader :expected_time, :start_time

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:ordered_splits, :expected_time, :start_time], class: self.class)
    @ordered_splits = args[:ordered_splits]
    @expected_time = args[:expected_time]
    @start_time = args[:start_time]
    @finder = args[:effort_finder] ||
        SimilarEffortFinder.new(sub_split: finish_sub_split, time_from_start: expected_time, split: finish_split)
    @times_calculator = args[:times_calculator] ||
        StatTimesCalculator.new(ordered_splits: ordered_splits,
                                completed_split_time: mock_finish_split_time,
                                similar_efforts: relevant_efforts)
    validate_setup
  end

  def indexed_split_times
    @indexed_split_times ||=
        ordered_sub_splits.map { |sub_split| SplitTime.new(split: indexed_splits[sub_split.split_id],
                                                           bitkey: sub_split.bitkey,
                                                           time_from_start: plan_times[sub_split]) }
            .index_by(&:sub_split)
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
    relevant_events.map(&:start_time).sort.map(&:year).uniq
  end

  def relevant_events
    @relevant_events ||= finder.events.to_a
  end

  def relevant_efforts
    @relevant_efforts ||= finder.efforts.to_a
  end

  private

  attr_accessor :relevant_split_times
  attr_reader :ordered_splits, :finder, :times_calculator

  def plan_times
    @plan_times ||= times_calculator.times_from_start
  end

  def create_split_rows
    prior_time = 0
    result = []
    ordered_splits.each do |split|
      split_row = SplitRow.new(split, related_split_times(split), prior_time, start_time)
      result << split_row
      prior_time = split_row.times_from_start.last
    end
    result
  end

  def mock_finish_split_time
    SplitTime.new(split: finish_split, bitkey: SubSplit::IN_BITKEY, time_from_start: expected_time)
  end

  def related_split_times(split)
    split.sub_splits.map { |sub_split| indexed_split_times[sub_split] }
  end

  def finish_split
    ordered_splits.last
  end

  def finish_sub_split
    finish_split.sub_split_in
  end

  def indexed_splits
    @indexed_splits ||= ordered_splits.index_by(&:id)
  end

  def ordered_sub_splits
    ordered_splits.map(&:sub_splits).flatten
  end

  def validate_setup
  end
end