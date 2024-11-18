# frozen_string_literal: true

module BadgeHelper
  def badge_with_text(text, options = {})
    color = options[:color] || "primary"
    tooltip_text = options[:tooltip_text]
    css_class = "badge bg-#{color} align-top"
    tooltip_data = tooltip_text.present? ? { controller: "tooltip", bs_original_title: tooltip_text } : {}

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
                class: "badge bg-#{color} align-top",
                data: { controller: :tooltip, bs_original_title: tooltip_text })
  end

  def historical_fact_kind_badge(kind)
    case kind
    when "dns"
      title = "DNS"
      color = :info
      tooltip_text = "Did not start"
    when "dnf"
      title = "DNF"
      color = :warning
      tooltip_text = "Started but did not finish"
    when "finished"
      title = "Finish"
      color = :primary
      tooltip_text = "Finished"
    when "volunteer_minor"
      title = "VMinor"
      color = :secondary
      tooltip_text = "Minor volunteer work for a specific event"
    when "volunteer_major"
      title = "VMajor"
      color = :secondary
      tooltip_text = "Major volunteer work for a specific event"
    when "volunteer_legacy"
      title = "VLegacy"
      color = :secondary
      tooltip_text = "Years of legacy volunteer work (no event specified)"
    when "reported_qualifier_finish"
      title = "Qualifier"
      color = :success
      tooltip_text = "Reported qualifier finished"
    when "provided_emergency_contact"
      title = "Contact"
      color = :success
      tooltip_text = "Provided emergency contact"
    when "provided_previous_name"
      title = "PrevName"
      color = :success
      tooltip_text = "Provided previous name"
    when "lottery_ticket_count_legacy"
      title = "Tickets"
      color = :dark
      tooltip_text = "Legacy ticket count calculation"
    when "lottery_division_legacy"
      title = "Division"
      color = :dark
      tooltip_text = "Legacy division determination"
    else
      raise ArgumentError, "Can't build a badge; unknown status: #{kind}"
    end

    content_tag(:span,
                title,
                style: "font-size:0.8rem;",
                class: "badge rounded-pill bg-#{color} align-top",
                data: { controller: :tooltip, bs_original_title: tooltip_text })
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
                class: "badge bg-#{color} align-top",
                data: { controller: :tooltip, bs_original_title: tooltip_text })
  end

  def waitlist_badge
    content_tag(:span,
                "Wait List",
                style: "font-size:0.8rem;",
                class: "badge bg-warning align-top")
  end
end