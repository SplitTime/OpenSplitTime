class UpdateEffortsStatusJob < ApplicationJob
  queue_as :default

  def perform(event_group, current_user: nil)
    set_current_user(current_user: current_user)

    event_group = EventGroup.where(id: event_group.id).includes(efforts: { split_times: :split }).first
    Interactors::UpdateEffortsStatus.perform!(event_group.efforts)
  end
end
