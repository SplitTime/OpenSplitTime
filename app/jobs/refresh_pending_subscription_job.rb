class RefreshPendingSubscriptionJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription&.pending?

    subscription.save

    return unless subscription.confirmed?

    Turbo::StreamsChannel.broadcast_replace_to(
      subscription.subscribable,
      target: ActionView::RecordIdentifier.dom_id(subscription.subscribable, subscription.protocol),
      partial: "subscriptions/subscription_button",
      locals: {
        subscribable: subscription.subscribable,
        protocol: subscription.protocol,
      },
    )
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
