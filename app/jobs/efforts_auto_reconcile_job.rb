class EffortsAutoReconcileJob < ApplicationJob

  queue_as :default

  def perform(event, options = {})
    ArgsValidator.validate(subject: event, subject_class: Event, params: options,
                           exclusive: [:background_channel, :current_user], class: self)
    User.current ||= options.delete(:current_user)
    EffortAutoReconciler.reconcile(event, options)
  end
end
