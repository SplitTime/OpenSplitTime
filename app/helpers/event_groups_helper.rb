# frozen_string_literal: true

module EventGroupsHelper
  def link_to_start_ready_group_efforts(view_object)
    if view_object.ready_efforts.present?
      link_to "Start #{pluralize(view_object.ready_efforts_count, 'effort')}",
              start_ready_efforts_event_group_path(view_object.event_group),
              method: :put,
              data: {confirm: 'NOTE: This will create a starting split time for the ' +
                  "#{pluralize(view_object.ready_efforts_count, 'unstarted effort')} " +
                  'scheduled to start before the current time. Are you sure you want to proceed?'},
              class: 'start-ready-efforts btn btn-sm btn-success'
    else
      link_to 'Nothing to start', '#', disabled: true,
              data: {confirm: 'No efforts are ready to start. Reload the page to check again.'},
              class: 'start-ready-efforts btn btn-sm btn-success'
    end
  end

  def link_to_summit_export(view_object)
    link_to 'Export to summit', export_to_summit_event_group_path(view_object.event_group, format: :csv),
            class: 'btn btn-sm btn-success'
  end
end
