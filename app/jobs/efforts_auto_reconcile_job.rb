# frozen_string_literal: true

class EffortsAutoReconcileJob < ApplicationJob

  queue_as :default

  def perform(parent, options = {})
    ArgsValidator.validate(subject: parent, params: options,
                           exclusive: [:background_channel, :current_user], class: self)
    set_current_user(options)

    EffortAutoReconciler.reconcile(parent, options)
  end
end
