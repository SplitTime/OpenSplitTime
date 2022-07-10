# frozen_string_literal: true

class PlanDisplay < EffortWithLapSplitRows
  MINIMUM_EFFORT_COUNT = 4

  include TimeFormats
  attr_reader :course, :error_messages

  delegate :name, :organization, :simple?, to: :course
  delegate :multiple_laps?, to: :event, allow_nil: true

  def initialize(args)
    @course = args[:course]
    @params = args[:params]
    @error_messages = []
    validate_setup
  end

  def effort
    @effort ||= event.efforts.new
  end

  def event
    @event ||= course.visible_events.latest
  end

  def ordered_split_times
    return [] if projected_effort.nil?
    return [] if projected_effort.effort_count < MINIMUM_EFFORT_COUNT

    projected_effort.ordered_split_times
  end

  def expected_time
    TimeConversion.hms_to_seconds(cleaned_time)
  end

  def cleaned_time
    time = (params[:expected_time] || "").gsub(/[^\d:]/, "").split(":").first(2).join(":")
    time.length.between?(1, 2) ? "#{time}:00" : time
  end

  def expected_laps
    params[:expected_laps].to_i.clamp(1, 20)
  end

  def start_time
    if params[:start_time].blank?
      default_start_time
    elsif params[:start_time].is_a?(String)
      ActiveSupport::TimeZone[default_time_zone].parse(params[:start_time])
    elsif params[:start_time].is_a?(ActionController::Parameters)
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

  def relevant_efforts_count
    projected_effort.effort_count
  end

  def event_years_analyzed
    projected_effort.effort_years
  end

  def plan_description
    formatted_time = time_format_hhmm(expected_time)
    lap_text = multiple_laps? ? "over #{expected_laps} laps" : nil
    ["Pacing plan for a #{formatted_time} effort", lap_text].compact.join(" ")
  end

  private

  attr_reader :params

  def projected_effort
    return unless expected_time && start_time

    @projected_effort ||= ProjectedEffort.new(
      event: event,
      start_time: start_time,
      baseline_split_time: baseline_split_time,
      projected_time_points: time_points,
    )
  end

  def baseline_split_time
    ::SplitTime.new(
      split: course.finish_split,
      bitkey: ::SubSplit::IN_BITKEY,
      lap: event.laps_required || expected_laps,
      absolute_time: start_time + expected_time,
      designated_seconds_from_start: expected_time / 1.second,
    )
  end

  def time_points
    @time_points ||= lap_splits.flat_map(&:time_points)
  end

  def lap_splits
    @lap_splits ||=
      begin
        laps = event.laps_required || expected_laps
        course.lap_splits_through(laps)
      end
  end

  def default_start_time
    return course.next_start_time.in_time_zone(default_time_zone) if course.next_start_time

    years_prior = Time.now.year - event.scheduled_start_time.year
    event.scheduled_start_time_local + (years_prior * 52.17).round(0).weeks
  end

  def default_time_zone
    event.home_time_zone
  end

  def validate_setup
    error_messages << "No events have been held on this course." if course.visible_events.empty?
    AssignSegmentTimes.perform(ordered_split_times) if error_messages.empty?
  rescue ArgumentError => e
    error_messages << e.message
  end
end
