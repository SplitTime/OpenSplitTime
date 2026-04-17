class EventUpdateStartTimeJob < ApplicationJob
  queue_as :default

  def perform(event, new_start_time:, current_user:)
    validate_setup(event)
    set_current_user(current_user: current_user)

    result = Interactors::ShiftEventStartTime.perform!(event, new_start_time: new_start_time)

    Rails.logger.debug result.message_with_error_report # TODO: use ActionCable to send this message to the session
    result
  end

  private

  def validate_setup(event)
    raise ArgumentError, "event must be an Event" unless event.is_a?(Event)
  end
end
