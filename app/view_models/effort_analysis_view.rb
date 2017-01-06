class EffortAnalysisView
  include EffortPlaceMethods

  attr_reader :effort, :analysis_rows
  delegate :full_name, :event_name, :participant, :bib_number, :finish_status, :gender, to: :effort

  def initialize(effort)
    @effort = effort
    @analysis_rows = []
    create_analysis_rows
  end

  def total_segment_time
    analysis_rows.sum(&:segment_time)
  end

  def total_segment_time_typical
    typical_effort.total_segment_time
  end

  def total_segment_time_over_under
    analysis_rows.sum(&:segment_time_over_under)
  end

  def total_time_in_aid
    analysis_rows.sum(&:time_in_aid)
  end

  def total_time_in_aid_typical
    typical_effort.total_time_in_aid
  end

  def total_time_in_aid_over_under
    analysis_rows.sum(&:time_in_aid_over_under)
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
    segment_count = [((sorted_analysis_rows.size / 2.0)).round(0), 3].min
    sorted_analysis_rows.first(segment_count).map(&:segment_name).join(', ')
  end

  def worst_segments
    segment_count = [(sorted_analysis_rows.size / 2), 3].min
    sorted_analysis_rows.reverse.first(segment_count).map(&:segment_name).join(', ')
  end

  def effort_finished?
    indexed_split_times[finish_sub_split].present?
  end

  def farthest_recorded_time
    split_times.present? ? split_times.last.time_from_start : nil
  end

  def farthest_recorded_split_name
    farthest_split = ordered_splits.find { |split| split.id == split_times.last.split_id }
    farthest_split && farthest_split.base_name
  end

  def event
    @event ||= effort.event
  end

  private

  attr_accessor :indexed_analysis_rows

  def typical_effort
    @typical_effort ||= mock_finish_time && MockEffort.new(ordered_splits: ordered_splits,
                                                           expected_time: mock_finish_time,
                                                           start_time: effort_start_time)
  end

  def indexed_typical_rows
    @indexed_typical_rows ||= typical_effort.split_rows.index_by(&:split_id)
  end

  def mock_finish_time
    effort_finish_tfs || focused_predicted_time || stats_predicted_time
  end

  def focused_predicted_time
    TimePredictor.segment_time(segment: start_to_finish, effort: effort, ordered_splits: ordered_splits,
                               calc_model: :focused, similar_effort_ids: similar_effort_ids)
  end

  def stats_predicted_time
    TimePredictor.segment_time(segment: start_to_finish, effort: effort, ordered_splits: ordered_splits,
                                calc_model: :stats)
  end

  def similar_effort_ids
    @similar_effort_ids ||= SimilarEffortFinder.new(split_time: split_times.last).effort_ids
  end

  def create_analysis_rows
    return unless typical_effort
    prior_split_time = related_split_times(ordered_splits.first).first
    prior_split = ordered_splits.first
    ordered_splits.each do |split|
      next if split.start?
      analysis_row = EffortAnalysisRow.new(split,
                                           related_split_times(split),
                                           prior_split,
                                           prior_split_time,
                                           effort_start_time,
                                           indexed_typical_rows[split.id])
      analysis_rows << analysis_row
      prior_split_time = analysis_row.split_times.compact.last if analysis_row.split_times.compact.present?
      prior_split = ordered_splits.find { |s| s.id == prior_split_time.split_id }
    end
    self.indexed_analysis_rows = analysis_rows.index_by(&:split_id)
  end

  def related_split_times(split)
    split.sub_splits.map { |sub_split| indexed_split_times[sub_split] }
  end

  def effort_start_time
    event.start_time + effort.start_offset
  end

  def effort_finish_tfs
    indexed_split_times[finish_sub_split].try(:time_from_start)
  end

  def finish_sub_split
    ordered_splits.last.sub_split_in
  end

  def start_sub_split
    ordered_splits.first.sub_split_in
  end

  def start_to_finish
    Segment.new(begin_sub_split: start_sub_split, end_sub_split: finish_sub_split)
  end

  def sorted_analysis_rows
    analysis_rows.select(&:segment_over_under_percent).sort_by(&:segment_over_under_percent)
  end

  def effort_in_progress?
    effort.dropped_split_id.nil? && indexed_split_times[finish_sub_split].nil?
  end

  def course
    @course ||= event.course
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end

  def split_times
    @split_times ||= effort.ordered_split_times.to_a
  end

  def indexed_split_times
    @indexed_split_times ||= split_times.index_by(&:sub_split)
  end
end