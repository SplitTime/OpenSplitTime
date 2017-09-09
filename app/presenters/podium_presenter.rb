class PodiumPresenter < BasePresenter

  delegate :name, :course, :course_name, :organization, :organization_name, :to_param, to: :event
  delegate :categories, to: :template

  def initialize(event, template)
    @event = event
    @template = template
  end
  
  def event_start_time
    event.start_time
  end

  private

  attr_reader :event, :template
end
