# frozen_string_literal: true

module CourseAnalysisMethods
  def event
    @event ||= course.visible_events.latest
  end

  private

  def default_start_time
    return course.next_start_time.in_time_zone(default_time_zone) if course.next_start_time

    years_prior = Time.now.year - event.scheduled_start_time.year
    event.scheduled_start_time_local + (years_prior * 52.17).round(0).weeks
  end

  def default_time_zone
    event.home_time_zone
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
end
