module ToastHelper
  def toast_icon_from_type(type)
    case type
    when "success"
      "circle-check"
    when "danger"
      "circle-exclamation"
    when "warning"
      "exclamation-triangle"
    when "info"
      "info-circle"
    else
      "info-circle"
    end
  end
end
