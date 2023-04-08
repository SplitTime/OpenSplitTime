# frozen_string_literal: true

module TooltipHelper
  def tooltip(text, placement: :top)
    options = { tabindex: -1,
                data: { controller: "tooltip",
                        bs_placement: placement,
                        bs_original_title: text } }
    content_tag(:span, text, options) do
      fa_icon("question-circle")
    end
  end
end
