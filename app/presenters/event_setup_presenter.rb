class EventSetupPresenter < BasePresenter
  include ::UnitConversions

  attr_reader :event, :view_context

  delegate :event_group, :new_record?, :organization, :to_param, to: :event
  delegate :id, to: :event, prefix: true
  delegate :available_live?, :concealed?, to: :event_group
  delegate :pref_distance_unit, to: :current_user

  def initialize(event, view_context)
    @event = event
    @view_context = view_context
    @params = view_context.params
    @current_user = view_context.current_user
  end

  def active_event
    event
  end

  def active_widget_card
    :events_and_courses
  end

  def course
    event.course || organization.courses.new.add_basic_splits!
  end

  def new_course
    organization.courses.new.add_basic_splits!
  end

  def start_split
    new_course.splits.find(&:start?)
  end

  def finish_split
    new_course.splits.find(&:finish?)
  end

  def courses_for_select
    available_courses = organization.courses.includes(:splits).order(:name).to_a
    # An event's course can belong to another organization; without it in the
    # options, the selector falls back to "Create a new course" and the form
    # submits a blank course_id
    if event.course.present? && available_courses.exclude?(event.course)
      available_courses = [event.course] + available_courses
    end

    course_options = available_courses.map do |course|
      [course.name, course.id, distance_component(course)]
    end

    [["Create a new course", nil, nil]] + course_options
  end

  def distance_component(course)
    { "data-distance" => course.distance && meters_to_preferred_distance(course.distance).round(1) }
  end

  def event_group_name
    event_group.name
  end

  def no_persisted_events?
    event_group.events.none?(&:persisted?)
  end

  def event_name
    event.name
  end

  def event_short_name_for_display
    event.short_name || "Single Event"
  end

  def organization_name
    organization.name
  end

  def status
    available_live? ? "live" : "not_live"
  end

  private

  attr_reader :params, :current_user
end
