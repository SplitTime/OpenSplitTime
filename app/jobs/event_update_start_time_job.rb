# frozen_string_literal: true

class EventUpdateStartTimeJob < ApplicationJob

  queue_as :default

  def perform(event, options)
    ArgsValidator.validate(subject: event, subject_class: Event, params: options, required: [:new_start_time],
                           exclusive: [:new_start_time, :background_channel, :current_user], class: self)
    set_current_user(options)

    Interactors::AdjustEventStartTime.perform!(event, options)
  end
end
