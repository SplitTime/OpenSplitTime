module PopoversHelper
  def link_to_effort_ids_popover(effort_ids, title)
    return "--" if effort_ids.empty?

    target_value = "popover_#{SecureRandom.hex(4)}"
    content_tag :a, effort_ids.size,
                tabindex: 0,
                class: "btn btn-sm btn-outline-primary fw-bold",
                data: {
                  controller: "popover",
                  popover_effort_ids_value: effort_ids,
                  popover_target_value: target_value,
                  bs_toggle: "popover",
                  bs_title: title,
                  bs_content: "<div id='#{target_value}'></div>",
                  bs_trigger: "focus",
                }
  end

  def link_to_static_popover(text:, content:, theme:, css_class:)
    content_tag :a, text,
                tabindex: 0,
                class: css_class,
                data: {
                  controller: "popover",
                  popover_theme_value: theme,
                  bs_toggle: "popover",
                  bs_content: content,
                  bs_trigger: "focus",
                }
  end
end
