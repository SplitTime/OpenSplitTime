# frozen_string_literal: true

class EffortAnalysisView < EffortWithLapSplitRows

  attr_reader :effort
  delegate :full_name, :event_name, :person, :bib_number, :finish_status, :gender,
           :overall_rank, :gender_rank, :start_time, :started?, to: :effort
  delegate :simple?, :multiple_sub_splits?, :event_group, to: :event

  def post_initialize(args_effort)
    @effort = args_effort.enriched || args_effort
  end

  def total_segment_time
    analysis_rows.map(&:segment_time).compact.sum
  end

  def total_segment_time_typical
    analysis_rows.map(&:segment_time_typical).compact.sum
  end

  def total_segment_time_over_under
    analysis_rows.map(&:segment_time_over_under).compact.sum
  end

  def total_time_in_aid
    analysis_rows.map(&:time_in_aid).compact.sum
  end

  def total_time_in_aid_typical
    analysis_rows.map(&:time_in_aid_typical).compact.sum
  end

  def total_time_in_aid_over_under
    analysis_rows.map(&:time_in_aid_over_under).compact.sum
  end

  def total_time_combined
    total_segment_time && total_time_in_aid && total_segment_time + total_time_in_aid
  end

  def total_time_combined_typical
    total_segment_time_typical && total_time_in_aid_typical && total_segment_time_typical + total_time_in_aid_typical
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

  def farthest_recorded_time
    effort.final_time_from_start
  end

  def farthest_recorded_split_name
    effort.final_split_name
  end

  def analysis_rows
    @analysis_rows ||= indexed_split_times.blank? ? nil :
                           lap_splits.each_cons(2).map do |prior_lap_split, lap_split|
                             EffortAnalysisRow.new(lap_split: lap_split,
                                                   split_times: related_split_times(lap_split),
                                                   typical_split_times: related_typical_split_times(lap_split),
                                                   prior_lap_split: prior_lap_split,
                                                   prior_split_time: prior_split_time(lap_split),
                                                   start_time: effort_start_time,
                                                   show_laps: event.multiple_laps?)
                           end
  end

  private

  def typical_effort
    @typical_effort ||= last_split_time && effort_start_time &&
        TypicalEffort.new(event: event,
                          expected_time_from_start: last_split_time.time_from_start,
                          start_time: effort_start_time,
                          time_points: ordered_split_times.map(&:time_point),
                          expected_time_point: last_split_time.time_point)
  end

  def last_split_time
    ordered_split_times.last
  end

  def sorted_analysis_rows
    analysis_rows.select(&:segment_over_under_percent).sort_by(&:segment_over_under_percent)
  end

  def course
    @course ||= event.course
  end

  def indexed_split_times
    @indexed_split_times ||= segmentize_relevant_times(ordered_split_times).index_by(&:time_point)
  end

  def indexed_typical_split_times
    @indexed_typical_split_times ||= segmentize_relevant_times(typical_effort.ordered_split_times).index_by(&:time_point)
  end

  def segmentize_relevant_times(split_times)
    relevant_split_times = split_times.select { |st| relevant_time_points.include?(st.time_point) }
    AssignSegmentTimes.perform(relevant_split_times)
  end

  def related_typical_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_typical_split_times.fetch(time_point, SplitTime.new) }
  end

  def relevant_time_points
    typical_effort ? ordered_split_times.map(&:time_point) & typical_effort.ordered_split_times.map(&:time_point) : []
  end
end
