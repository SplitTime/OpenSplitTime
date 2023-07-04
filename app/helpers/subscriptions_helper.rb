module SubscriptionsHelper
  def subscription_status_badge(subscription)
    pending = subscription.resource_key.start_with?("pending")
    text = pending ? "Pending" : "Confirmed"
    color = pending ? "warning" : "success"
    badge_with_text(text, color: color)
  end
end
