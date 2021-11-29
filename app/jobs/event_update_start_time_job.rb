# frozen_string_literal: true

class EventUpdateStartTimeJob < ApplicationJob

  queue_as :default

  def perform(event, options)
    ArgsValidator.validate(subject: event, subject_class: Event, params: options, required: [:new_start_time, :current_user],
                           exclusive: [:new_start_time, :current_user], class: self)

    set_current_user(options)
    result = Interactors::ShiftEventStartTime.perform!(event, options)

    pp result.message_with_error_report # TODO use ActionCable to send this message to the session
    result
  end
end
