# frozen_string_literal: true

class CourseCutoffAnalysisPresenter < BasePresenter
  include SplitAnalyzable
  include TimeFormats

  attr_reader :course, :band_width

  delegate :name, :organization, :simple?, to: :course

  def initialize(course, view_context)
    @course = course
    @view_context = view_context
    @parameterized_split_name = view_context.prepared_params[:parameterized_split_name]
    @band_width = view_context.prepared_params[:band_width]&.to_i || 30.minutes
  end

  def interval_split_cutoff_analyses
    @interval_split_cutoff_analyses ||= ::IntervalSplitCutoffAnalysis.execute_query(split: split, band_width: band_width)
  end

  def chart_data
    @chart_data ||=
      [
        {
          name: "Finished",
          data: interval_split_cutoff_analyses.map { |isca| [duration_range_string(isca), isca.finished_count] }
        },
        {
          name: "Unfinished",
          data: interval_split_cutoff_analyses.map { |isca| [duration_range_string(isca), isca.total_count - isca.finished_count] }
        },
      ]
  end

  def distance
    split&.distance_from_start
  end

  def table_title
    if split.nil?
      "Unknown split."
    elsif interval_split_cutoff_analyses.nil?
      "Too many rows to analyze. Use a lower frequency."
    elsif interval_split_cutoff_analyses.empty?
      "No data is available for this aid station."
    else
      "Cutoff analysis for #{split_name} in increments of #{band_width / 1.minute} minutes"
    end
  end

  def duration_range_string(isca)
    "#{time_format_hhmm(isca.start_seconds)} to #{time_format_hhmm(isca.end_seconds)}"
  end

  def split_name
    split.base_name
  end

  def suggested_band_widths
    [1.minute, 2.minutes, 5.minutes, 10.minutes, 15.minutes, 30.minutes, 60.minutes]
  end

  private

  attr_reader :parameterized_split_name

  def split
    @split ||= course.splits.find_by(parameterized_base_name: parameterized_split_name) || course.ordered_splits.second
  end

  def split_analyzable
    course
  end

  def localized_time(datetime)
    I18n.localize(datetime.in_time_zone(event_group.home_time_zone), format: :day_and_military)
  end
end
