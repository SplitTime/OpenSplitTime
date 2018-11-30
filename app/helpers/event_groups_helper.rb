# frozen_string_literal: true

module EventGroupsHelper
  def link_to_start_ready_efforts(view_object)
    if view_object.ready_efforts.present?
      link_to "Start #{pluralize(view_object.ready_efforts_count, 'effort')}",
              start_efforts_event_group_path(view_object.event_group, filter: {ready_to_start: true}),
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
            class: 'btn btn-md btn-success'
  end

  def lap_and_time_builder(bib_row)
    bib_row.split_times.map do |st|
      lap_prefix = bib_row.single_lap ? '' : "Lap #{st.lap}:  "
      lap_prefix + st.military_time
    end.join("\n")
  end
end
