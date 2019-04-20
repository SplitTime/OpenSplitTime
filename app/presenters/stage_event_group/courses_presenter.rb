# frozen_string_literal: true

class StageEventGroup::CoursesPresenter < StageEventGroup::BasePresenter
  def post_initialize(_)
  end

  def courses
    events.map(&:course).uniq
  end

  def first_course_event
    @first_course_event ||= event_group.events.where(course_id: course.id).first
  end

  def course_has_location_data?
    course.ordered_splits.any?(&:has_location?) || course.gpx.attached?
  end

  def current_step
    'courses'
  end

  private

  def distance_component(course)
    {'data-distance' => (course.distance && StagingForm.meters_to_preferred_distance(course.distance).round(1))}
  end

  attr_reader :current_user
end