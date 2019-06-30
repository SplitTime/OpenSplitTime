# frozen_string_literal: true

class StageEventGroup::EventDetailsPresenter < StageEventGroup::BasePresenter
  attr_reader :event

  def post_initialize
    @event = event_from_id || new_event
    assign_event_attributes
  end

  def courses_for_select
    Course.all.includes(:splits).order(:name).map { |course| [course.name, course.id, distance_component(course)] }
  end

  def cancel_link
    case
    when existing_events.present?
      Rails.application.routes.url_helpers.edit_stage_event_group_path(event_group, step: :event_details, event: {id: ordered_events.first.id})
    else
      Rails.application.routes.url_helpers.edit_stage_event_group_path(event_group, step: :your_event)
    end
  end

  def current_step
    'event_details'
  end

  private

  attr_reader :current_user

  def new_event
    Event.new(default_event_attributes)
  end

  def assign_event_attributes
    event.assign_attributes(permitted_event_params) if params[:event].present?
    event.assign_attributes(course_id: params[:course_id]) if params[:course_id].present?
  end

  def distance_component(course)
    {'data-distance' => (course.distance && StageEventGroup::BasePresenter.meters_to_preferred_distance(course.distance).round(1))}
  end

  def default_event_attributes
    course = Course.find_by(id: params[:course_id])
    start_time_local = existing_events.last&.start_time_local || I18n.l(Date.tomorrow + 6.hours, format: :datetime_input)
    {event_group: event_group, course: course, results_template: ResultsTemplate.default, laps_required: 1, start_time_local: start_time_local}
  end

  def permitted_event_params
    EventParameters.strong_params(params)
  end

  def existing_events
    ordered_events.select(&:persisted?)
  end
end
