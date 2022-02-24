# frozen_string_literal: true

module BadgeHelper
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
                class: "badge badge-#{color} align-top has-tooltip",
                data: {toggle: "tooltip", "original-title" => tooltip_text})
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
                class: "badge badge-#{color} align-top has-tooltip",
                data: {toggle: "tooltip", "original-title" => tooltip_text})
  end

  def waitlist_badge
    content_tag(:span,
                "Wait List",
                style: "font-size:0.8rem;",
                class: "badge badge-warning align-top")
  end
end