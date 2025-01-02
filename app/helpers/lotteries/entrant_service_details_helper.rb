module Lotteries::EntrantServiceDetailsHelper
  def button_to_remove_completed_service_form(presenter)
    url = remove_completed_form_organization_lottery_entrant_service_detail_path(presenter.organization, presenter.lottery, presenter.__getobj__)
    options = {
      method: :delete,
      class: "btn btn-outline-danger",
    }

    button_to(url, options) { fa_icon("file-xmark", text: "Remove") }
  end

  def service_form_status_with_icon(entrant_service_detail)
    case
    when entrant_service_detail.nil? || entrant_service_detail.completed_form.blank?
      title = "Not received"
      icon = "file-slash"
      color = "warning"
    when entrant_service_detail.rejected?
      title = "Rejected"
      icon = "file-circle-xmark"
      color = "danger"
    when entrant_service_detail.accepted?
      title = "Accepted"
      icon = "memo-circle-check"
      color = "success"
    else
      title = "Under review"
      icon = "file-magnifying-glass"
      color = "secondary"
    end

    content_tag :span, fa_icon(icon, type: :regular, text: title, class: "text-#{color}")
  end
end
