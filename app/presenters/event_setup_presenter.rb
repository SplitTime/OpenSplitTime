# frozen_string_literal: true

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

  def course
    event.course || organization.courses.new.add_basic_splits!
  end

  def start_split
    course.splits.find(&:start?)
  end

  def finish_split
    course.splits.find(&:finish?)
  end

  def courses_for_select
    available_courses = organization.courses.includes(:splits).order(:name).map do |course|
      [course.name, course.id, distance_component(course)]
    end

    [["Create a new course", nil, nil]] + available_courses
  end

  def distance_component(course)
    {"data-distance" => (course.distance && meters_to_preferred_distance(course.distance).round(1))}
  end

  def event_group_name
    event_group.name
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
