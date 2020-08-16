# frozen_string_literal: true

class CoursePresenter < BasePresenter
  attr_reader :course
  delegate :id, :name, :description, :ordered_splits, :simple?, to: :course

  def initialize(course, params, current_user)
    @course = course
    @params = params
    @current_user = current_user
  end

  def course_has_location_data?
    ordered_splits.any?(&:has_location?) || gpx.attached?
  end

  def display_style
    params[:display_style] == 'splits' ? 'splits' : 'events'
  end

  def events
    @events ||= ::EventPolicy::Scope.new(current_user, course.events).viewable.order(scheduled_start_time: :desc).to_a
  end

  def organization
    @organization ||= Organization.joins(event_groups: :events).where(events: {course_id: course.id}).first
  end

  def show_visibility_columns?
    current_user&.admin?
  end

  private

  attr_reader :params, :current_user
  delegate :gpx, to: :course
end
