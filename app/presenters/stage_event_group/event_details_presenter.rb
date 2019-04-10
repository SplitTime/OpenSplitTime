# frozen_string_literal: true

class StageEventGroup::EventDetailsPresenter < StageEventGroup::BasePresenter
  attr_reader :course, :event

  def post_initialize
    @event = params[:event_id] ? event_group.events.find(params[:event_id]) : new_event
    @course = params[:course_id] ? Course.find(id: params[:course_id]) : event.course
    start_time_local = I18n.l(Date.tomorrow + 6.hours, format: :datetime_input)
    event.assign_attributes(course: course, results_template: ResultsTemplate.default, laps_required: 1, start_time_local: start_time_local)
  end

  def courses
    events.map(&:course).uniq
  end

  def courses_for_select
    Course.all.includes(:splits).order(:name).map { |course| [course.name, course.id, distance_component(course)] }
  end

  def cancel_link
  end

  def first_course_event
    @first_course_event ||= event_group.events.where(course_id: course.id).first
  end

  def course_has_location_data?
    course.ordered_splits.any?(&:has_location?) || course.gpx.attached?
  end

  private

  attr_reader :current_user

  def distance_component(course)
    {'data-distance' => (course.distance && StageEventGroup::BasePresenter.meters_to_preferred_distance(course.distance).round(1))}
  end

  def new_event
    Event.new(event_group: event_group)
  end
end