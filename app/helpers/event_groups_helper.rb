# frozen_string_literal: true

module EventGroupsHelper
  def link_to_start_ready_efforts(view_object)
    if view_object.ready_efforts.present?
      content_tag :div, class: 'btn-group' do
        concat content_tag(:button, class: 'btn btn-success dropdown-toggle start-ready-efforts',
                           data: {toggle: :dropdown}) {
          safe_concat 'Start efforts'
          safe_concat '&nbsp;'
          concat content_tag(:span, '', class: 'caret')
        }

        concat content_tag(:div, class: 'dropdown-menu') {
          view_object.ready_efforts.count_by(&:assumed_start_time_local).sort.each do |time, effort_count|
            display_time = l(time, format: :full_day_military_and_zone)
            concat content_tag(:div, "(#{effort_count}) scheduled at #{display_time}",
                               {class: 'dropdown-item', data: {action: 'click->roster#showModal',
                                                               title: "Start #{pluralize(effort_count, 'Effort')}",
                                                               time: time.in_time_zone('UTC').to_s,
                                                               displaytime: l(time, format: :datetime_input)}})
          end
        }
      end
    else
      link_to 'Nothing to start', '#', disabled: true,
              data: {confirm: 'No entrants are ready to start. Reload the page to check again.'},
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
