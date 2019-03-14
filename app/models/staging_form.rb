# frozen_string_literal: true

class StagingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include UnitConversions
  validates_presence_of :event_group, :step

  def self.steps
    [:your_event, :event_details, :courses, :entrants, :confirmation, :published]
  end

  attr_reader :step, :event_group, :event, :course
  delegate :name, :organization, :organization_name, :events, :to_param, to: :event_group
  delegate :pref_distance_unit, :pref_elevation_unit, to: :current_user

  def initialize(attributes)
    @step = attributes[:step]
    @event_group = attributes[:event_group]
    @event = attributes[:event]
    @course = attributes[:course]
    @current_user = attributes[:current_user]
  end

  def step_enabled?(step)
    case step
    when :your_event
      true
    when :event_details
      event_group.persisted?
    when :courses
      events.present?
    when :entrants
      events.present?
    when :confirmation
      events.present?
    when :published
      events.present? && events.all? { |event| event.efforts.present? }
    else
      false
    end
  end

  def courses_for_select
    Course.all.includes(:splits).order(:name).map { |course| [course.name, course.id, distance_component(course)] }
  end

  def cancel_link
    case step
    when :your_event
      case
      when event_group.persisted?
        Rails.application.routes.url_helpers.event_group_path(event_group, force_settings: true)
      when organization.persisted?
        Rails.application.routes.url_helpers.organization_path(organization)
      else
        Rails.application.routes.url_helpers.event_groups_path
      end

    when :event_details

    end
  end

  private

  def distance_component(course)
    {'data-distance' => (course.distance && StagingForm.meters_to_preferred_distance(course.distance).round(1))}
  end

  attr_reader :current_user
end
