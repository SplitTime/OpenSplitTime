# frozen_string_literal: true

class StageEventGroup::CoursesPresenter < StageEventGroup::BasePresenter
  attr_reader :course

  def post_initialize
    @course = course_from_id || event_from_id&.course || courses.first
  end

  def courses
    @courses ||= ordered_events.map(&:course).uniq
  end

  def first_course_event
    @first_course_event ||= events.where(course_id: course.id).first
  end

  def course_has_location_data?
    course.ordered_splits.any?(&:has_location?) || course.gpx.attached?
  end

  def current_step
    'courses'
  end

  private

  attr_reader :current_user

  def distance_component(course)
    {'data-distance' => (course.distance && StagingForm.meters_to_preferred_distance(course.distance).round(1))}
  end

  def course_from_id
    return nil unless course_id.present?
    courses.find { |course| course.id == course_id.to_i }
  end

  def course_id
    params.dig(:course, :id)
  end

  def event_id
    params.dig(:event, :id)
  end
end
