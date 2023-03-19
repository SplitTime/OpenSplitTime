# frozen_string_literal: true

module NavigationHelper
  def link_to_refresh
    tooltip_title = "Refresh [Ctrl-R]"
    content_tag(:span, data: {controller: "navigation animation"}) do
      link_to fa_icon(:redo),
              request.params,
              id: "refresh-button",
              class: "btn btn-primary has-tooltip",
              data: {action: "click->animation#spinIcon keyup@document->navigation#evaluateKeyup",
                     "navigation-target" => "refreshButton",
                     "bs-toggle": "tooltip",
                     placement: :bottom,
                     "original-title" => tooltip_title}
    end
  end

  def prior_next_nav_button(view_object, prior_or_next, param: :parameterized_split_name)
    icon_name = prior_or_next == :prior ? 'caret-left' : 'caret-right'
    target = view_object.send("#{prior_or_next}_#{param}")
    merge_param = target.present? ? {param => target} : {}
    titleized_prior_or_next = prior_or_next.to_s.titleize
    tooltip_title = "#{titleized_prior_or_next} [Ctrl-#{titleized_prior_or_next.first}]"

    content_tag :span, data: {controller: :navigation} do
      link_to fa_icon(icon_name, class: 'fa-lg'),
              request.params.merge(merge_param),
              id: "#{prior_or_next}-button",
              class: 'btn btn-outline-secondary has-tooltip',
              data: {action: 'keyup@document->navigation#evaluateKeyup',
                     "navigation-target" => "#{prior_or_next}Button",
                     "bs-toggle": 'tooltip',
                     placement: :bottom,
                     'original-title' => tooltip_title},
              disabled: target.blank?
    end
  end
end
