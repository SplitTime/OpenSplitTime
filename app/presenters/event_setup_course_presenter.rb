# frozen_string_literal: true

class EventSetupCoursePresenter < BasePresenter
  def initialize(event, view_context)
    @event = event
    @view_context = view_context
    @course = event.course
    @event_group = event.event_group
  end

  attr_reader :course, :event, :event_group
  delegate :description, :name, :ordered_splits, :organization, to: :course
  delegate :concealed?, :status, to: :event_group

  def aid_stations_by_split_id
    @aid_stations_by_split_id ||= event.aid_stations.index_by(&:split_id)
  end

  def course_id
    course.id
  end

  def course_name
    course.name
  end

  def event_group_name
    event_group.name
  end

  def event_name
    event.guaranteed_short_name
  end

  def status
    event_group.available_live? ? "live" : "not_live"
  end

  private

  attr_reader :view_context

end
