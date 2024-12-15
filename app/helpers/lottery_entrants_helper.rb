# frozen_string_literal: true

module LotteryEntrantsHelper
  def button_to_remove_completed_service_form(presenter)
    url = remove_service_form_organization_lottery_lottery_entrant_path(presenter.organization, presenter.lottery, presenter.__getobj__)
    options = {
      method: :delete,
      class: "btn btn-outline-danger",
    }

    button_to(url, options) { fa_icon("file-xmark", text: "Remove") }
  end

  def service_form_status_with_icon(lottery_entrant)
    status = lottery_entrant.service_form_status
    uploaded = lottery_entrant.completed_service_form.attached?

    unless status.in? ["accepted", "rejected", nil]
      raise ArgumentError, "No case available in display_service_form_status for status: #{status}"
    end

    case
    when status.nil? && !uploaded
      title = "Not received"
      icon = "file-slash"
      color = "warning"
    when status.nil? && uploaded
      title = "Under review"
      icon = "file-magnifying-glass"
      color = "secondary"
    when status == "rejected"
      title = "Rejected"
      icon = "file-circle-xmark"
      color = "danger"
    else
      title = "Accepted"
      icon = "memo-circle-check"
      color = "success"
    end

    content_tag :span, fa_icon(icon, type: :regular, text: title, class: "fs-4 text-#{color}"), class: "fw-bold fs-5"
  end
end
