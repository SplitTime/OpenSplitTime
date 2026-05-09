class EventUpdateStartTimeJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(event, new_start_time:, current_user:)
    validate_setup(event)
    set_current_user(current_user: current_user)

    result = Interactors::ShiftEventStartTime.perform!(event, new_start_time: new_start_time)

    if result.successful?
      broadcast_flash(event.event_group, message: "#{result.message} Refresh the page to see changes.")
    else
      broadcast_flash(event.event_group, message: result.message, level: :danger)
    end
    result
  end

  private

  def validate_setup(event)
    raise ArgumentError, "event must be an Event" unless event.is_a?(Event)
  end
end
