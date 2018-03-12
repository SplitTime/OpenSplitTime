# frozen_string_literal: true

class EffortsAutoReconcileJob < ApplicationJob

  queue_as :default

  def perform(event, options = {})
    ArgsValidator.validate(subject: event, subject_class: Event, params: options,
                           exclusive: [:background_channel, :current_user], class: self)
    set_current_user(options)

    EffortAutoReconciler.reconcile(event, options)
  end
end
