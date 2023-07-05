# frozen_string_literal: true

class EventGroupFollowPresenter < BasePresenter
  attr_reader :event_group, :current_user

  delegate :name, :organization, :organization_name, :events, :home_time_zone, :scheduled_start_time_local, :available_live,
           :multiple_events?, to: :event_group

  def initialize(event_group, view_context)
    @event_group = event_group
    @params = view_context.params
    @current_user = view_context.current_user
  end

  def event
    event_group.first_event
  end

  def courses
    events.map(&:course).uniq
  end

  def effort_planning_available?
    complex_events_included? && complex_precedents_available?
  end

  def event_group_finished?
    event_group.finished?
  end

  def multiple_courses?
    courses.many?
  end

  def other_events_available?
    organization.event_groups.visible.many?
  end

  def webhooks_available?
    events.having_topic_resource_key.any?
  end

  private

  def complex_events_included?
    events.any? { |event| !event.simple? }
  end

  def complex_precedents_available?
    courses.any? { |course| course.events.any? { |event| event.finished? && !event.simple? } }
  end
end
