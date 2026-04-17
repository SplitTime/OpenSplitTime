class EventUpdateStartTimeJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(event, new_start_time:, current_user:)
    validate_setup(event)
    set_current_user(current_user: current_user)

    result = Interactors::ShiftEventStartTime.perform!(event, new_start_time: new_start_time)

    message = "#{result.message} Refresh the page to see changes."
    level = result.successful? ? :success : :danger
    broadcast_flash(event.event_group, message: message, level: level)
    result
  end

  private

  def validate_setup(event)
    raise ArgumentError, "event must be an Event" unless event.is_a?(Event)
  end
end
