# frozen_string_literal: true

class StageEventGroup::EventDetails
  def self.update(event_group, params)
    permitted_params = EventParameters.strong_params(params).except(:event_group_id)
    event_id = permitted_params[:id]
    event = event_id ? event_group.events.find(event_id) : event_group.events.new
    event.assign_attributes(permitted_params)
    response = event.save
    event_group.errors.merge!(event.errors)
    response
  end
end
