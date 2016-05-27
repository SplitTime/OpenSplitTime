class EffortShowView
  attr_reader :effort, :split_rows

  def initialize(effort)
    @effort = effort
    @splits = effort.event.ordered_splits.to_a
    @split_times = effort.split_times.index_by(&:key_hash)
    @split_rows = []
    create_split_rows
  end

  def total_time_in_aid
    split_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  private

  attr_reader :splits, :split_times

  def create_split_rows
    prior_time = 0
    splits.each do |split|
      split_row = SplitRow.new(split, related_split_times(split), prior_time)
      split_rows << split_row
      prior_time = split_row.times_from_start.last
    end
  end

  def related_split_times(split)
    split.sub_split_key_hashes.collect { |key_hash| split_times[key_hash] }
  end

end