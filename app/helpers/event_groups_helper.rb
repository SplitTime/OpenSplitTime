# frozen_string_literal: true

module EventGroupsHelper
  def link_to_summit_export(view_object)
    link_to 'Export to summit', export_to_summit_event_group_path(view_object.event_group, format: :csv),
            class: 'btn btn-sm btn-success'
  end
end
