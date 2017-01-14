class EffortShowView

  attr_reader :effort, :event, :split_rows
  delegate :full_name, :event_name, :participant, :bib_number, :gender, :split_times,
           :finish_status, :report_url, :beacon_url, :dropped_split_id, :start_time, :photo_url,
           :overall_place, :gender_place, :started?, :finished?, :dropped?, :in_progress?, to: :effort
  delegate :simple?, to: :event

  def initialize(args_effort)
    @effort = args_effort.enriched || args_effort
    @event = effort.event
    @splits = effort.ordered_splits.to_a
    @split_times = effort.split_times.index_by(&:sub_split)
    @split_rows = []
    create_split_rows
  end

  def total_time_in_aid
    split_rows.sum(&:time_in_aid)
  end

  def not_analyzable?
    split_times.size < 2
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
    split.sub_splits.collect { |key_hash| split_times[key_hash] }
  end

  def finish_sub_split
    {splits.last.id => SubSplit::IN_BITKEY}
  end
end