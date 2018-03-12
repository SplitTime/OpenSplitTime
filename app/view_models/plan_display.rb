# frozen_string_literal: true

class PlanDisplay

  attr_reader :course, :expected_time, :expected_laps

  delegate :relevant_events, :relevant_efforts, :lap_split_rows, :total_segment_time, :total_time_in_aid,
           :relevant_efforts_count, :event_years_analyzed, to: :mock_effort
  delegate :multiple_laps?, to: :event

  def initialize(course, params)
    @course = course
    @params = params
  end

  def event
    @event ||= course.events.visible.latest
  end

  def expected_time
    TimeConversion.hms_to_seconds(cleaned_time)
  end

  def cleaned_time
    (params[:expected_time] || '').gsub(/[^\d:]/, '').split(':').first(2).join(':')
  end

  def expected_laps
    params[:expected_laps].to_i.clamp(1, 20)
  end

  def start_time
    params[:start_time].present? ? TimeConversion.components_to_absolute(params[:start_time]) : default_start_time
  end

  def course_name
    course.name
  end

  def out_sub_splits?
    lap_splits.any?(&:time_point_out)
  end

  private

  attr_reader :params

  def mock_effort
    @mock_effort ||= MockEffort.new(event: event, expected_time: expected_time,
                                    expected_laps: expected_laps, start_time: start_time) if expected_time && start_time
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(expected_laps)
  end

  def default_start_time
    return course.next_start_time.in_time_zone(default_time_zone) if course.next_start_time
    years_prior = Time.now.year - event.start_time.year
    event.start_time_in_home_zone + ((years_prior * 52.17).round(0)).weeks
  end

  def default_time_zone
    event.home_time_zone
  end
end
