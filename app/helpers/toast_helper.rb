# frozen_string_literal: true

module ToastHelper
  def toast_icon_from_type(type)
    case type
    when "success"
      "check-circle"
    when "danger"
      "exclamation-circle"
    when "warning"
      "exclamation-triangle"
    when "info"
      "info-circle"
    else
      "info-circle"
    end
  end
end
