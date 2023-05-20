# frozen_string_literal: true

class CourseCutoffAnalysisPresenter < BasePresenter
  include CourseAnalysisMethods
  include SplitAnalyzable
  include TimeFormats

  DEFAULT_BAND_WIDTH = 30.minutes
  DEFAULT_DISPLAY_STYLE = "absolute_time"
  VALID_DISPLAY_STYLES = %w(elapsed_time absolute_time).freeze

  attr_reader :course
  delegate :events, :name, :organization, :simple?, to: :course

  def initialize(course, view_context)
    @course = course
    @view_context = view_context
  end

  def interval_split_cutoff_analyses
    @interval_split_cutoff_analyses ||= ::IntervalSplitCutoffAnalysis.execute_query(split: split, band_width: band_width)
  end

  def band_width
    @band_width ||= params[:band_width]&.to_i || DEFAULT_BAND_WIDTH
  end

  def chart_data
    @chart_data ||=
      [
        {
          name: "Finished",
          data: interval_split_cutoff_analyses.map { |isca| [range_string(isca), isca.finished_count] }
        },
        {
          name: "Stopped Here",
          data: interval_split_cutoff_analyses.map { |isca| [range_string(isca), isca.stopped_here_count] }
        },
        {
          name: "Continued and DNF",
          data: interval_split_cutoff_analyses.map { |isca| [range_string(isca), isca.continued_dnf_count] }
        },
      ]
  end

  def display_style
    params[:display_style].in?(VALID_DISPLAY_STYLES) ? params[:display_style] : DEFAULT_DISPLAY_STYLE
  end

  def display_style_hash
    {
      elapsed_time: "Elapsed",
      absolute_time: "Absolute",
    }.with_indifferent_access.freeze
  end

  def distance
    split&.distance_from_start
  end

  def range_string(isca)
    if display_style == "elapsed_time"
      "#{time_format_hhmm(isca.start_seconds)} to #{time_format_hhmm(isca.end_seconds)}"
    else
      "#{localized_time(start_time + isca.start_seconds)} to #{localized_time(start_time + isca.end_seconds)}"
    end
  end

  def parameterized_split_name
    @parameterized_split_name ||= params[:parameterized_split_name] || default_split.parameterized_base_name
  end

  def split_name
    split.base_name
  end

  def suggested_band_widths
    [1.minute, 2.minutes, 5.minutes, 10.minutes, 15.minutes, 30.minutes, 60.minutes]
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

  def visible_events_exist?
    events.visible.exists?
  end

  private

  attr_reader :view_context
  delegate :params, to: :view_context, private: true

  def split
    @split ||= course.splits.find_by(parameterized_base_name: parameterized_split_name) || default_split
  end

  def default_split
    @default_split ||= course.ordered_splits.second
  end

  def split_analyzable
    course
  end

  def localized_time(datetime)
    I18n.localize(datetime, format: :day_and_military)
  end
end
