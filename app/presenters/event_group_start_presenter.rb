# Lightweight substitute for EventGroupRosterPresenter used where no
# view_context exists (e.g. broadcast renders from a background job)
class EventGroupStartPresenter
  attr_reader :event_group

  def initialize(event_group)
    @event_group = event_group
  end

  def ready_efforts
    @ready_efforts ||= event_group.efforts.roster_subquery.select(&:ready_to_start)
  end
end
