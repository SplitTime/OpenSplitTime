class RefreshPendingSubscriptionJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription&.pending?

    subscription.save

    return unless subscription.confirmed?

    Turbo::StreamsChannel.broadcast_refresh_to(subscription.subscribable)
    broadcast_flash(
      subscription.subscribable,
      message: I18n.t(
        "subscriptions.confirmed",
        protocol: subscription.protocol,
        name: subscription.subscribable.name,
      ),
    )
  end
end
