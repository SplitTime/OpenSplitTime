# Override the form_tag helper to add spam protection to forms.
module SpamProtectionHelper
  def captcha_div
    html_id = "username_#{Time.current.to_i + rand(999)}".gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_")

    content_tag :div, {id: html_id, class: "form-group d-none"} do
      label_tag("user_username", "Do not put anything here") +
        text_field_tag(:username, nil, id: "user_username")
    end.html_safe
  end

  def timestamp_element
    hidden_field_tag(:timestamp, Time.current.to_i)
  end
end
