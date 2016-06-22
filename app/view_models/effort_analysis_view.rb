class EffortAnalysisView

  attr_reader :effort, :event, :analysis_rows
  delegate :full_name, :event_name, :participant, :bib_number, :combined_places, :finish_status,
           :gender, to: :effort

  def initialize(effort)
    @effort = effort
    @event = @effort.event
    @splits = @effort.event.ordered_splits.to_a
    @split_times = @effort.ordered_split_times.to_a
    @indexed_split_times = @split_times.index_by(&:bitkey_hash)
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
    analysis_rows.map(&:segment_time_over_under).sum
  end

  def total_time_in_aid
    analysis_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  def total_time_in_aid_typical
    typical_effort.total_time_in_aid
  end

  def total_time_in_aid_over_under
    analysis_rows.map(&:time_in_aid_over_under).sum
  end

  def total_time_combined
    (total_segment_time && total_time_in_aid) ? total_segment_time + total_time_in_aid : nil
  end

  def total_combined_time_over_under
    total_segment_time_over_under + total_time_in_aid_over_under
  end

  def typical_finish_tfs
    typical_effort.finish_time_from_start
  end

  def best_segments
    segment_count = [((sortable_analysis_rows.count / 2.0)).round(0), 3].min
    sortable_analysis_rows.sort_by(&:segment_over_under_percent).first(segment_count).map(&:segment_name).join(', ')
  end

  def worst_segments
    segment_count = [(sortable_analysis_rows.count / 2), 3].min
    sortable_analysis_rows.sort_by(&:segment_over_under_percent).reverse.first(segment_count).map(&:segment_name).join(', ')
  end

  private

  attr_accessor :typical_effort, :indexed_typical_rows, :indexed_analysis_rows
  attr_reader :splits, :split_times, :indexed_split_times

  def create_typical_effort
    mock_target_time = effort_finish_tfs || effort.expected_time_from_start(finish_bitkey_hash)
    self.typical_effort = MockEffort.new(event, mock_target_time, effort_start_time, relevant_calc_splits)
    self.indexed_typical_rows = typical_effort
                                    .split_rows
                                    .index_by(&:split_id)
  end

  def create_analysis_rows
    prior_split_time = related_split_times(splits.first).first
    prior_split = splits.first
    splits.each do |split|
      next if split.start?
      analysis_row = EffortAnalysisRow.new(split,
                                           related_split_times(split),
                                           prior_split,
                                           prior_split_time,
                                           effort_start_time,
                                           indexed_typical_rows[split.id])
      analysis_rows << analysis_row
      prior_split_time = analysis_row.split_times.compact.last if analysis_row.split_times.compact.present?
      prior_split = splits.find { |s| s.id == prior_split_time.split_id }
    end
    self.indexed_analysis_rows = analysis_rows.index_by(&:split_id)
  end

  def relevant_calc_splits
    splits = effort_in_progress? ? (recorded_splits + incomplete_splits).flatten : recorded_splits
    splits.sort_by!(&:distance_from_start)
  end

  def recorded_splits
    splits.select { |split| split_times.map(&:split_id).include?(split.id) }
  end

  def incomplete_splits
    splits[splits.index(recorded_splits.last) + 1..-1]
  end

  def related_split_times(split)
    split.sub_split_bitkey_hashes.collect { |key_hash| indexed_split_times[key_hash] }
  end

  def effort_start_time
    event.start_time + effort.start_offset
  end

  def effort_finish_tfs
    indexed_split_times[finish_bitkey_hash] ? indexed_split_times[finish_bitkey_hash].time_from_start : nil
  end

  def finish_bitkey_hash
    splits.last.bitkey_hash_in
  end

  def sortable_analysis_rows
    analysis_rows.select { |row| row.segment_over_under_percent }
  end

  def effort_in_progress?
    effort.dropped_split_id.nil? && indexed_split_times[finish_bitkey_hash].nil?
  end

end