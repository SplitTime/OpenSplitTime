# frozen_string_literal: true

module BadgeHelper
  def badge_with_text(text, options = {})
    color = options[:color] || "primary"
    tooltip_text = options[:tooltip_text]
    css_class_tooltip = tooltip_text.present? ? "has-tooltip" : nil
    css_class = "badge bg-#{color} align-top #{css_class_tooltip}"
    tooltip_data = tooltip_text.present? ? { "bs-toggle": "tooltip", "bs-original-title": tooltip_text } : {}

    content_tag(:span,
                text,
                style: "font-size:0.8rem;",
                class: css_class,
                data: tooltip_data)
  end

  def construction_status_badge(status)
    case status
    when "not_live"
      color = :primary
      tooltip_text = "Live entry is not available; this event group will not be visible in OST Remote"
    when "live"
      color = :danger
      tooltip_text = "Live entry is available; this event group will be visible to authorized users in OST Remote"
    else
      raise ArgumentError, "Can't build a badge; unknown status: #{status}"
    end

    content_tag(:span,
                status.titleize,
                style: "font-size:0.8rem;",
                class: "badge bg-#{color} align-top has-tooltip",
                data: { "bs-toggle": "tooltip", "bs-original-title": tooltip_text })
  end

  def lottery_status_badge(status)
    case status
    when "preview"
      color = :primary
      tooltip_text = "Draws and results are not available to the public"
    when "live"
      color = :danger
      tooltip_text = "Draws and results are available to the public; live updating animation is enabled"
    when "finished"
      color = :success
      tooltip_text = "Draws and results are available to the public; live updating animation is disabled"
    else
      raise ArgumentError, "Can't build a badge; unknown status: #{status}"
    end

    content_tag(:span,
                status.titleize,
                style: "font-size:0.8rem;",
                class: "badge bg-#{color} align-top has-tooltip",
                data: { "bs-toggle": "tooltip", "bs-original-title": tooltip_text })
  end

  def waitlist_badge
    content_tag(:span,
                "Wait List",
                style: "font-size:0.8rem;",
                class: "badge bg-warning align-top")
  end
end