# frozen_string_literal: true

class PodiumPresenter < BasePresenter

  attr_reader :event
  delegate :name, :course, :course_name, :organization, :organization_name, :to_param, :multiple_laps?,
           :event_group, :podium_template, :ordered_events_within_group, to: :event
  delegate :available_live, to: :event_group

  def initialize(event, template)
    @event = event
    @template = template
  end
  
  def event_start_time
    event.start_time
  end

  def categories
    template&.categories
  end

  def template_name
    template&.name
  end

  private

  attr_reader :template
end
