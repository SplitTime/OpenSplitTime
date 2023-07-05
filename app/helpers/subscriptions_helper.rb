# frozen_string_literal: true

module SubscriptionsHelper
  def subscription_status_badge(subscription)
    pending = subscription.resource_key.start_with?("pending")
    text = pending ? "Pending" : "Confirmed"
    color = pending ? "warning" : "success"
    tooltip_text = pending ?
                     "This subscription is pending confirmation. If you have confirmed the endpoint, click Actions > Refresh to change its status here." :
                     "This subscription is confirmed."
    badge_with_text(text, color: color, tooltip_text: tooltip_text)
  end
end
