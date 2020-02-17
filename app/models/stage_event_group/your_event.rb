# frozen_string_literal: true

class StageEventGroup::YourEvent
  def self.update(event_group, params)
    permitted_params = EventGroupParameters.strong_params(params)
    event_group.update(permitted_params)
  end
end
