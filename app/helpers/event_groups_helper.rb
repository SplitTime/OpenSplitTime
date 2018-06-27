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
              class: 'start-ready-efforts btn btn-md btn-success'
    else
      link_to 'Nothing to start', '#', disabled: true,
              data: {confirm: 'No efforts are ready to start. Reload the page to check again.'},
              class: 'start-ready-efforts btn btn-md btn-success'
    end
  end

  def link_to_set_data_status(view_object)
    link_to 'Set data status', set_data_status_event_group_path(view_object.event_group),
            method: :put,
            class: 'btn btn-md btn-success'
  end

  def link_to_export_raw_times(view_object, split_name, csv_template)
    link_to 'Export', export_raw_times_event_group_path(view_object.event_group, split_name: split_name, csv_template: csv_template, format: :csv),
            class: 'btn btn-md btn-success pull-right'
  end

  def link_to_raw_times(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group)
      content_tag :li, class: "#{'active' if action_name == 'raw_times'}" do
        link_to 'Raw times', raw_times_event_group_path(view_object.event_group)
      end
    end
  end

  def link_to_split_raw_times(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group)
      content_tag :li, class: "#{'active' if action_name == 'split_raw_times'}" do
        link_to 'Split raw times', split_raw_times_event_group_path(view_object.event_group)
      end
    end
  end

  def link_to_enter_group_live_entry(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group) && view_object.available_live
      content_tag :li, class: "#{'active' if action_name == 'live_entry'}" do
        link_to 'Live Entry', live_entry_live_event_group_path(view_object.event_group)
      end
    end
  end

  def link_to_progress_report(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group) && view_object.available_live
      content_tag :li, class: "#{'active' if action_name == 'progress_report'}" do
        link_to 'Progress', progress_report_live_event_path(view_object.event)
      end
    end
  end

  def link_to_drop_list(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group) && view_object.available_live
      content_tag :li, class: "#{'active' if action_name == 'drop_list'}" do
        link_to 'Drops', drop_list_event_path(view_object.event)
      end
    end
  end

  def link_to_aid_station_list(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group) && view_object.available_live
      content_tag :li, class: "#{'active' if action_name == 'aid_station_report'}" do
        link_to 'Aid stations', aid_station_report_live_event_path(view_object.event)
      end
    end
  end
end
