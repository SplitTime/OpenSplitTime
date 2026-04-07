class UpdateEffortsStatusJob < ApplicationJob
  queue_as :default

  def perform(event_group, current_user: nil)
    set_current_user(current_user: current_user)

    event_group = EventGroup.where(id: event_group.id).includes(efforts: { split_times: :split }).first
    response = Interactors::UpdateEffortsStatus.perform!(event_group.efforts)

    Turbo::StreamsChannel.broadcast_replace_to(
      event_group,
      target: "flash",
      partial: "layouts/flash",
      locals: { flash: { success: response.message } }
    )
  end
end
