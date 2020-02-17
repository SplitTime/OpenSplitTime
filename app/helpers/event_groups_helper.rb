# frozen_string_literal: true

module EventGroupsHelper
  def organizations_selector(form)
    organizations = OrganizationPolicy::Scope.new(current_user, Organization).editable.sort_by(&:name)

    form.collection_select(:organization_id, organizations, :id, :name,
                           {prompt: 'Choose an organization'},
                           {autofocus: true,
                            class: "form-control dropdown-select-field",
                            data: {target: 'eg-form.orgDropdown',
                                   action: 'eg-form#setOrgForm eg-form#fillEventGroupName'}})
  end

  def link_to_start_ready_efforts(view_object)
    if view_object.ready_efforts.present?
      content_tag :div, class: 'btn-group' do
        concat content_tag(:button, class: 'btn btn-success dropdown-toggle start-ready-efforts',
                           data: {toggle: :dropdown}) {
          safe_concat 'Start entrants'
          safe_concat '&nbsp;'
          concat content_tag(:span, '', class: 'caret')
        }

        concat content_tag(:div, class: 'dropdown-menu') {
          view_object.ready_efforts.count_by(&:assumed_start_time_local).sort.each do |time, effort_count|
            display_time = l(time, format: :full_day_military_and_zone)
            concat content_tag(:div, "(#{effort_count}) scheduled at #{display_time}",
                               {class: 'dropdown-item', data: {action: 'click->roster#showModal',
                                                               title: "Start #{pluralize(effort_count, 'Entrant')}",
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
