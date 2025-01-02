module NavigationHelper
  def link_to_refresh
    tooltip_title = "Refresh [Ctrl-R]"
    link_to fa_icon(:rotate_right),
            request.params,
            id: "refresh-button",
            class: "btn btn-primary",
            data: { controller: "navigation animation tooltip",
                    action: "click->animation#spinIcon keyup@document->navigation#evaluateKeyup",
                    "navigation-target" => "refreshButton",
                    bs_placement: :bottom,
                    bs_original_title: tooltip_title }
  end

  def prior_next_nav_button(view_object, prior_or_next, param: :parameterized_split_name)
    icon_name = prior_or_next == :prior ? "caret-left" : "caret-right"
    target = view_object.send("#{prior_or_next}_#{param}")
    merge_param = target.present? ? { param => target } : {}
    titleized_prior_or_next = prior_or_next.to_s.titleize
    tooltip_title = "#{titleized_prior_or_next} [Ctrl-#{titleized_prior_or_next.first}]"

    link_to fa_icon(icon_name, class: "fa-lg"),
            request.params.merge(merge_param),
            id: "#{prior_or_next}-button",
            class: "btn btn-outline-secondary",
            data: { controller: "navigation tooltip",
                    action: "keyup@document->navigation#evaluateKeyup",
                    "navigation-target" => "#{prior_or_next}Button",
                    bs_placement: :bottom,
                    bs_original_title: tooltip_title },
            disabled: target.blank?
  end
end
