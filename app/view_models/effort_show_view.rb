class EffortShowView
  include EffortPlaceMethods

  attr_reader :effort, :event, :split_rows
  delegate :full_name, :event_name, :participant, :bib_number, :gender, :split_times,
           :finish_status, :report_url, :beacon_url, :dropped_split_id, :start_time,
           :photo_url, to: :effort
  delegate :simple?, to: :event

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

  def started?
    split_times.present?
  end

  def in_progress?
    !dropped? && !finished?
  end

  def not_analyzable?
    split_times.count < 2
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

  def dropped?
    effort.dropped_split_id.present?
  end

  def finished?
    split_times[finish_bitkey_hash].present?
  end

  def finish_bitkey_hash
    {splits.last.id => SubSplit::IN_BITKEY}
  end

end