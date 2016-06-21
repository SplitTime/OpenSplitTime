class EffortShowView

  attr_reader :effort, :event, :split_rows
  delegate :full_name, :event_name, :participant, :bib_number, :combined_places, :finish_status,
           :gender, :split_times, to: :effort

  def initialize(effort)
    @effort = effort
    @event = effort.event
    @splits = effort.event.ordered_splits.to_a
    @split_times = effort.split_times.index_by(&:bitkey_hash)
    @split_rows = []
    create_split_rows
  end

  def total_time_in_aid
    split_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  private

  attr_reader :splits, :split_times

  def create_split_rows
    start_time = event.start_time + effort.start_offset
    prior_time = 0
    splits.each do |split|
      split_row = SplitRow.new(split, related_split_times(split), prior_time, start_time)
      split_rows << split_row
      prior_time = split_row.times_from_start.compact.last if split_row.times_from_start.compact.present?
    end
  end

  def related_split_times(split)
    split.sub_split_bitkey_hashes.collect { |key_hash| split_times[key_hash] }
  end

end