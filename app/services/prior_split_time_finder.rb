class PriorSplitTimeFinder

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :sub_split,
                           required_alternatives: [:effort, [:ordered_splits, :split_times]],
                           class: self.class)
    @sub_split = args[:sub_split]
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @split_times = args[:split_times] || effort.ordered_split_times.to_a
    validate_setup
  end

  def split_time
    @split_time ||= relevant_sub_splits.map { |sub_split| indexed_split_times[sub_split] }.compact.last
  end

  def guaranteed_split_time
    @guaranteed_split_time ||= split_time || mock_start_split_time
  end

  private

  attr_reader :effort, :sub_split, :ordered_splits, :split_times

  def relevant_sub_splits
    sub_split_index.zero? ? [] : ordered_sub_splits[0..sub_split_index - 1]
  end

  def mock_start_split_time
    SplitTime.new(sub_split: ordered_sub_splits.first, time_from_start: 0)
  end

  def sub_split_index
    ordered_sub_splits.index(sub_split)
  end

  def ordered_sub_splits
    @ordered_sub_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_split_times
    @indexed_split_times ||= valid_split_times.index_by(&:sub_split)
  end

  def valid_split_times
    split_times.select(&:valid_status?)
  end

  def validate_setup
    raise ArgumentError, 'sub_split is not contained in the provided splits' unless
        ordered_sub_splits.include?(sub_split)
    raise ArgumentError, 'split_times do not all belong to the same effort' unless
        split_times.map(&:effort_id).uniq.count < 2
    raise ArgumentError, 'split_times do not relate to the provided effort' if
        effort && split_times.any? { |st| st.effort_id != effort.id }
  end
end