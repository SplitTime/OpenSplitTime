# frozen_string_literal: true

module FormatHelper
  def strong_text_conditional(true_text, false_text, boolean)
    boolean ? strong_conditional(true_text, boolean) : strong_conditional(false_text, boolean)
  end

  def strong_conditional(text, boolean)
    boolean ? content_tag(:strong, text) : text
  end
end
