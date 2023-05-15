# frozen_string_literal: true

module SplitsHelper
  def link_to_event_split_delete(event, split)
    link_to_delete_resource(fa_icon("trash-alt"), event_group_event_split_path(event.event_group, event, split),
                            resource: split,
                            noteworthy_associations: [:split_times],
                            additional_warning: "NOTE: This applies to the current Event and to all Events that are now using or have used this Split in the past.",
                            class: "btn btn-sm btn-outline-danger")
  end

  def link_to_event_split_edit(event, split)
    url = edit_event_group_event_split_path(event.event_group, event, split)
    tooltip = "Edit this split"
    options = { data: { turbo_frame: "form_modal",
                        controller: "tooltip",
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-sm btn-outline-primary" }
    link_to fa_icon("pencil-alt"), url, options
  end
end
