# frozen_string_literal: true

module SubscriptionsHelper
  def subscription_status_badge(subscription)
    if subscription.resource_key.blank?
      text = "No topic"
      color = "danger"
      tooltip_text = "This event does not have a topic resource key. Click Actions > Refresh to attempt to generate one, or delete this subscription and create a new one."
    elsif subscription.pending?
      text = "Pending"
      color = "warning"
      tooltip_text = "This subscription is pending confirmation. If you have confirmed the endpoint, click Actions > Refresh to change its status here."
    else
      text = "Confirmed"
      color = "success"
      tooltip_text = "This subscription is confirmed."
    end

    badge_with_text(text, color: color, tooltip_text: tooltip_text)
  end
end
