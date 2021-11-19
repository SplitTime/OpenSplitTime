# frozen_string_literal: true

module ConcealedHelper
  def name_with_concealed_indicator(presenter)
    icon_name = presenter.concealed? ? "eye-slash" : "eye"
    tooltip_text = presenter.concealed? ? "Lottery is not visible to the public" : "Lottery is visible to the public"

    concat presenter.name.html_safe
    concat " "
    fa_icon(icon_name,
            class: "has-tooltip",
            data: {toggle: "tooltip", "original-title" => tooltip_text})
  end
end
