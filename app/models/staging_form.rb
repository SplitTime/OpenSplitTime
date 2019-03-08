# frozen_string_literal: true

class StagingForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  validates_presence_of :event_group, :step

  def self.steps
    [:your_event, :event_details, :courses, :entrants, :confirmation, :published]
  end

  attr_reader :step, :event_group, :event, :course
  delegate :name, :organization, :organization_name, :events, :to_param, to: :event_group

  def initialize(attributes)
    @step = attributes[:step]
    @event_group = attributes[:event_group]
    @event = attributes[:event]
    @course = attributes[:course]
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

  private

end
