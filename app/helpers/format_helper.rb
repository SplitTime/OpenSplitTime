# frozen_string_literal: true

module FormatHelper
  def data_status_text_class
    {'bad' => 'text-danger', 'questionable' => 'text-warning'}
  end

  def strong_text_conditional(true_text, false_text, boolean)
    boolean ? strong_conditional(true_text, boolean) : strong_conditional(false_text, boolean)
  end

  def strong_conditional(text, boolean)
    boolean ? content_tag(:strong, text) : text
  end
end
