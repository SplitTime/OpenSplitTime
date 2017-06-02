class EffortsAutoReconcileJob < ActiveJob::Base

  queue_as :default

  def perform(args)
    ArgsValidator.validate(params: args, required: :event, exclusive: [:event, :background_channel], class: self)
    EffortAutoReconciler.reconcile(args)
  end
end
