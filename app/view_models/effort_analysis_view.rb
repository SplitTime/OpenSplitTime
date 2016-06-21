class EffortAnalysisView

  attr_reader :effort, :event, :analysis_rows
  delegate :full_name, :event_name, :participant, :bib_number, :combined_places, :finish_status,
           :gender, :split_times, to: :effort

  def initialize(effort)
    @effort = effort
    @event = effort.event
    @splits = effort.event.ordered_splits.to_a
    @split_times = effort.split_times.index_by(&:bitkey_hash)
    create_typical_effort
    @analysis_rows = []
    create_analysis_rows
  end

  def total_segment_time
    analysis_rows.sum { |row| row.segment_time }
  end

  def total_segment_time_typical
    typical_effort.total_segment_time
  end

  def total_segment_time_over_under
    total_segment_time - total_segment_time_typical
  end

  def total_time_in_aid
    analysis_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  def total_time_in_aid_typical
    typical_effort.total_time_in_aid
  end

  def total_time_in_aid_over_under
    total_time_in_aid - total_time_in_aid_typical
  end

  def total_combined_time_over_under
    total_segment_time_over_under + total_time_in_aid_over_under
  end

  # private

  attr_accessor :typical_effort, :indexed_typical_rows, :indexed_analysis_rows
  attr_reader :splits, :split_times

  def create_typical_effort
    self.typical_effort = MockEffort.new(event, effort_finish_tfs, effort_start_time)
    self.indexed_typical_rows = typical_effort.split_rows.index_by(&:split_id)
  end

  def create_analysis_rows
    prior_time = 0
    splits.each do |split|
      next if split.start?
      analysis_row = EffortAnalysisRow.new(split, related_split_times(split), prior_time, effort_start_time, indexed_typical_rows[split.id])
      analysis_rows << analysis_row
      prior_time = analysis_row.times_from_start.compact.last if analysis_row.times_from_start.compact.present?
    end
    self.indexed_analysis_rows = analysis_rows.index_by(&:split_id)
  end

  def related_split_times(split)
    split.sub_split_bitkey_hashes.collect { |key_hash| split_times[key_hash] }
  end

  def effort_start_time
    event.start_time + effort.start_offset
  end

  def effort_finish_tfs
    finish_bitkey_hash = splits.last.bitkey_hash_in
    split_times[finish_bitkey_hash].time_from_start
  end

end