# frozen_string_literal: true

class PlanDisplay < EffortWithLapSplitRows
  include TimeFormats
  attr_reader :course
  delegate :name, :organization, :simple?, to: :course
  delegate :multiple_laps?, to: :event, allow_nil: true

  def initialize(args)
    @course = args[:course]
    @params = args[:params]
    @error_messages = []
    validate_setup
  end

  attr_reader :error_messages

  def effort
    @effort ||= event.efforts.new
  end

  def event
    @event ||= course.visible_events.latest
  end

  def ordered_split_times
    typical_effort&.ordered_split_times || []
  end

  def expected_time
    TimeConversion.hms_to_seconds(cleaned_time)
  end

  def cleaned_time
    time = (params[:expected_time] || '').gsub(/[^\d:]/, '').split(':').first(2).join(':')
    time.length.between?(1, 2) ? "#{time}:00" : time
  end

  def expected_laps
    params[:expected_laps].to_i.clamp(1, 20)
  end

  def start_time
    case
    when params[:start_time].blank?
      default_start_time
    when params[:start_time].is_a?(String)
      ActiveSupport::TimeZone[default_time_zone].parse(params[:start_time])
    when params[:start_time].is_a?(ActionController::Parameters)
      TimeConversion.components_to_absolute(params[:start_time]).in_time_zone(default_time_zone)
    else
      default_start_time
    end
  end

  def course_name
    course.name
  end

  def out_sub_splits?
    lap_splits.any?(&:time_point_out)
  end

  def total_segment_time
    lap_split_rows.map(&:segment_time).compact.sum
  end

  def finish_time_from_start
    ordered_split_times.last.absolute_time - start_time
  end

  def relevant_efforts_count
    relevant_effort_ids.size
  end

  def event_years_analyzed
    relevant_events.map(&:scheduled_start_time).sort.map(&:year).uniq
  end

  def relevant_events
    @relevant_events ||= effort_finder.events.to_a
  end

  def relevant_efforts
    @relevant_efforts ||= effort_finder.efforts.to_a
  end

  def plan_description
    formatted_time = time_format_hhmm(expected_time)
    lap_text = multiple_laps? ? "over #{expected_laps} laps" : nil
    ["Pacing plan for a #{formatted_time} effort", lap_text].compact.join(' ')
  end

  private

  attr_reader :params

  def typical_effort
    @typical_effort ||= TypicalEffort.new(event: event,
                                          expected_time_from_start: expected_time,
                                          start_time: start_time,
                                          time_points: time_points) if expected_time && start_time
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(expected_laps)
  end

  def effort_finder
    typical_effort.similar_effort_finder
  end

  def relevant_effort_ids
    effort_finder.effort_ids
  end

  def default_start_time
    return course.next_start_time.in_time_zone(default_time_zone) if course.next_start_time
    years_prior = Time.now.year - event.scheduled_start_time.year
    event.scheduled_start_time_local + ((years_prior * 52.17).round(0)).weeks
  end

  def default_time_zone
    event.home_time_zone
  end

  def validate_setup
    error_messages << "No events have been held on this course." if course.visible_events.empty?
    AssignSegmentTimes.perform(ordered_split_times) if error_messages.empty?
  rescue ArgumentError => error
    error_messages << error.message
  end
end
