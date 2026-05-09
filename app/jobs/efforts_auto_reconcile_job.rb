class EffortsAutoReconcileJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(event_group, background_channel: nil, current_user: nil)
    options = { background_channel: background_channel, current_user: current_user }.compact
    set_current_user(options)

    report = EffortAutoReconciler.reconcile(event_group, options)
    broadcast_flash(event_group, message: report)
    Turbo::StreamsChannel.broadcast_refresh_to(event_group)
  end
end
