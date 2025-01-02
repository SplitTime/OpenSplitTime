module FormatHelper
  def pretty_duration(seconds)
    return "--:--" unless seconds.present?

    parse_string = seconds < 3600 ? "%M:%S" : "%H:%M:%S"
    Time.at(seconds).utc.strftime(parse_string)
  end

  def strong_text_conditional(true_text, false_text, boolean)
    boolean ? strong_conditional(true_text, boolean) : strong_conditional(false_text, boolean)
  end

  def strong_conditional(text, boolean)
    boolean ? content_tag(:strong, text) : text
  end
end
