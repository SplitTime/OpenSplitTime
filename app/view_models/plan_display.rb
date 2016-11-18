class PlanDisplay

  attr_reader :course

  delegate :relevant_events, :relevant_efforts, :split_rows, :total_segment_time, :total_time_in_aid,
           :relevant_efforts_count, :event_years_analyzed, to: :mock_effort

  def initialize(course, params)
    @course = course
    @params = params
  end

  def event
    @event ||= course.events.where(concealed: false).latest
  end

  def start_time
    @start_time ||= params[:start_time].present? ?
        TimeConversion.components_to_absolute(params[:start_time]) :
        default_start_time
  end

  def expected_time
    @expected_time = expected_time_from_param(params[:expected_time])
  end

  def course_name
    course.name
  end

  private

  attr_reader :params

  def mock_effort
    @mock_effort ||=
        MockEffort.new(course: course, expected_time: expected_time, start_time: start_time) if expected_time && start_time
  end

  def expected_time_from_param(entered_time)
    entered_time.present? ? TimeConversion.hms_to_seconds(entered_time.gsub(/[^\d:]/, '')) : nil
  end

  def default_start_time
    return course.next_start_time.in_time_zone if course.next_start_time
    years_prior = Time.now.year - event.start_time.year
    event.start_time + (years_prior * 52.17.to_i).weeks
  end
end