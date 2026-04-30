class RefreshPendingSubscriptionJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription&.pending?

    subscription.save

    return unless subscription.confirmed?

    # Replace just the subscription button rather than the whole page.
    # broadcast_refresh_to would trigger a full page re-fetch that wipes the
    # flash element rendered by broadcast_flash below. The replacement is the
    # lazy turbo-frame partial; the browser fetches its src in a request
    # context (current_user available) and Turbo swaps the contents.
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
