class EventUpdateStartTimeJob < ActiveJob::Base

  queue_as :default

  def perform(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :new_start_time],
                           exclusive: [:event, :new_start_time, :background_channel],
                           class: self)
    Interactors::AdjustEventStartTime.perform!(args)
  end
end
