module ConcealedHelper
  def name_with_concealed_indicator(name, concealed)
    icon_name = concealed ? "eye-slash" : "eye"
    tooltip_text = concealed ? "Not visible to the public" : "Visible to the public"

    concat name.html_safe
    concat " "
    fa_icon(icon_name, data: { controller: :tooltip, bs_original_title: tooltip_text })
  end
end
