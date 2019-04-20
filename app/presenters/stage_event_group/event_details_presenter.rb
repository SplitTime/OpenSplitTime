# frozen_string_literal: true

class StageEventGroup::EventDetailsPresenter < StageEventGroup::BasePresenter
  attr_reader :course, :event

  def post_initialize
    @event = existing_event || new_event
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

  def existing_event
    return nil unless event_id.present?
    found_event = event_group.events.find(event_id)
    found_event.assign_attributes(permitted_event_params)
    found_event
  end

  def new_event
    Event.new(default_event_attributes)
  end

  def default_event_attributes
    course = params[:course_id] ? Course.find(id: params[:course_id]) : nil
    start_time_local = I18n.l(Date.tomorrow + 6.hours, format: :datetime_input)
    {event_group: event_group, course: course, results_template: ResultsTemplate.default, laps_required: 1, start_time_local: start_time_local}
  end

  def permitted_event_params
    EventParameters.strong_params(params)
  end

  def event_id
    params.dig(:event, :id)
  end
end
