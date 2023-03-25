# frozen_string_literal: true

module PopoversHelper
  def link_to_effort_ids_popover(effort_ids, title)
    return "--" if effort_ids.empty?

    content_tag :a, effort_ids.size,
                tabindex: 0,
                class: "btn btn-sm btn-outline-primary fw-bold",
                data: {
                  controller: "popover",
                  popover_effort_ids_value: effort_ids,
                  bs_toggle: "popover",
                  bs_title: title,
                  bs_content: "Loading...",
                  bs_trigger: "focus",
                }
  end
end
