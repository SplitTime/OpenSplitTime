# frozen_string_literal: true

module SplitsHelper
  def link_to_event_split_edit(event, split)
    url = edit_event_group_event_split_path(event.event_group, event, split)
    tooltip = "Edit this split"
    options = { data: { turbo_frame: "form_modal",
                        controller: "tooltip",
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-primary" }
    link_to fa_icon("pencil-alt"), url, options
  end
end
