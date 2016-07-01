class PlanDisplay

  attr_reader :course, :expected_time, :start_time

  delegate :relevant_events, :relevant_efforts, :split_rows, :total_segment_time, :total_time_in_aid,
           :relevant_efforts_count, :event_years_analyzed, to: :mock_effort

  MAX_EVENTS = 5

  def initialize(course, params, event = nil)
    @course = course
    @event = event || course.events.where(demo: false).latest
    @expected_time = expected_time_from_param(params[:expected_time])
    if @event
      @start_time = params[:start_time].present? ? convert_to_datetime(params[:start_time]) : default_start_time
    end
    if @event && @expected_time
      @mock_effort = MockEffort.new(@event, expected_time, start_time)
    end
  end

  def course_name
    course.name
  end

  private

  attr_reader :event, :mock_effort

  def expected_time_from_param(entered_time)
    return nil unless entered_time.present?
    clean_time = entered_time.gsub(/[^\d:]/, '')
    clean_time.concat("00") if entered_time.last == ":"
    return nil unless clean_time =~ /^\d{1,2}(:\d{2})?$/
    time_components = clean_time.split(":")
    hours = time_components[0].to_i
    minutes = time_components[1].to_i
    ((hours * 60 * 60) + (minutes * 60))
  end

  def default_start_time
    return course.next_start_time.in_time_zone if course.next_start_time
    years_prior = Time.now.year - event.start_time.year
    shift_forward = (years_prior * 52.weeks) + ((years_prior / 6).weeks)
    event.start_time + shift_forward
  end

  def convert_to_datetime(datetime_components)
    DateTime.new(datetime_components["date(1i)"].to_i,
                 datetime_components["date(2i)"].to_i,
                 datetime_components["date(3i)"].to_i,
                 datetime_components["date(4i)"].to_i,
                 datetime_components["date(5i)"].to_i)
  end

end