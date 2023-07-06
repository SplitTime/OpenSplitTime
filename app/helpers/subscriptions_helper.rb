# frozen_string_literal: true

module SubscriptionsHelper
  def subscription_status_badge(subscription)
    if subscription.resource_key.blank?
      text = "No topic"
      color = "danger"
      tooltip_text = t("subscriptions.tooltips.no_topic")
    elsif subscription.pending?
      text = "Pending"
      color = "warning"
      tooltip_text = t("subscriptions.tooltips.pending")
    else
      text = "Confirmed"
      color = "success"
      tooltip_text = t("subscriptions.tooltips.confirmed")
    end

    badge_with_text(text, color: color, tooltip_text: tooltip_text)
  end
end
