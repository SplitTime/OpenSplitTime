class EffortsAutoReconcileJob < ApplicationJob
  queue_as :default

  def perform(parent, background_channel: nil, current_user: nil)
    options = { background_channel: background_channel, current_user: current_user }.compact
    set_current_user(options)

    EffortAutoReconciler.reconcile(parent, options)
  end
end
