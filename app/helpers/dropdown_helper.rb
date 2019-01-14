# frozen_string_literal: true

module DropdownHelper
  def build_dropdown_menu(title, items, options = {})
    main_active = items.any? { |item| item[:active] } ? 'active' : nil

    container_tag = options[:button] ? :div : :li
    container_class = options[:button] ? 'btn-group' : main_active
    content_tag container_tag, class: [container_class, options[:class]].join(' ') do
      toggle_tag = options[:button] ? :button : :a
      toggle_class = (options[:button] ? 'btn btn-outline-secondary' : '') + ' dropdown-toggle'
      concat content_tag(toggle_tag, class: toggle_class, data: {toggle: 'dropdown'}) {
        active_name = items.find { |item| item[:active] }&.dig(:name)
        safe_concat [title, active_name].compact.join(' / ')
        safe_concat '&nbsp;'
        concat content_tag(:span, '', class: 'caret')
      }

      concat content_tag(:div, class: 'dropdown-menu') {
        items.reject { |item| item[:visible] == false }.each do |item|
          if item[:role] == :separator
            concat content_tag(:div, '', class: 'dropdown-divider')
          else
            active = item[:active] ? 'active' : nil
            html_class = ['dropdown-item', active, item[:class]].compact.join(' ')
            concat link_to item[:name], item[:link], {class: html_class}.merge(item.slice(:method, :data))
          end
        end
      }
    end
  end

  def admin_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'Staging',
         link: "#{event_staging_app_path(view_object.event)}#/#{event_staging_app_page(view_object)}",
         active: action_name == 'app'},
        {name: 'Roster',
         link: roster_event_group_path(view_object.event_group),
         active: action_name == 'roster' && !params[:problem]},
        {name: 'Problems',
         link: roster_event_group_path(view_object.event_group, problem: true),
         active: action_name == 'roster' && params[:problem]},
        {name: 'Settings',
         link: event_group_path(view_object.event_group, force_settings: true),
         active: controller_name == 'event_groups' && action_name == 'show'}
    ]
    build_dropdown_menu('Admin', dropdown_items, class: 'nav-item')
  end

  def live_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'Time Entry',
         link: live_entry_live_event_group_path(view_object.event_group),
         active: action_name == 'live_entry',
         visible: view_object.available_live},
        {name: 'Drops',
         link: drop_list_event_group_path(view_object.event_group),
         active: action_name == 'drop_list'},
        {name: 'Progress',
         link: progress_report_live_event_path(view_object.event),
         active: action_name == 'progress_report'},
        {name: 'Aid Stations',
         link: aid_station_report_live_event_path(view_object.event),
         active: action_name == 'aid_station_report'},
        {name: 'Aid Detail',
         link: aid_station_detail_live_event_path(view_object.event),
         active: action_name == 'aid_station_detail'}
    ]
    build_dropdown_menu('Live', dropdown_items, class: 'nav-item')
  end

  def results_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'List',
         link: event_path(view_object.event),
         active: controller_name == 'events' && action_name == 'show'},
        {name: 'Spread',
         link: spread_event_path(view_object.event),
         active: action_name == 'spread'},
        {name: 'Summary',
         link: summary_event_path(view_object.event),
         active: action_name == 'summary'},
        {name: 'Podium',
         link: podium_event_path(view_object.event),
         active: action_name == 'podium'},
        {name: 'Traffic',
         link: traffic_event_group_path(view_object.event_group),
         active: action_name == 'traffic'}
    ]
    build_dropdown_menu('Results', dropdown_items, class: 'nav-item')
  end

  def raw_times_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'List',
         link: raw_times_event_group_path(view_object.event_group),
         active: action_name == 'raw_times'},
        {name: 'Splits',
         link: split_raw_times_event_group_path(view_object.event_group),
         active: action_name == 'split_raw_times'}
    ]
    build_dropdown_menu('Raw Times', dropdown_items, class: 'nav-item')
  end

  def check_in_filter_dropdown_menu
    items = [{icon_name: 'exclamation-circle', type: :solid, text: 'Problems', problem: true},
             {icon_name: 'question-circle', type: :solid, text: 'Unreconciled', unreconciled: true},
             {icon_name: 'square', type: :regular, text: 'Not checked', checked_in: false, started: false},
             {icon_name: 'check-square', type: :regular, text: 'Checked in', checked_in: true, started: false},
             {icon_name: 'caret-square-right', type: :regular, text: 'Started', started: true},
             {icon_name: 'asterisk', type: :solid, text: 'All'}]

    dropdown_items = items.map do |item|
      {name: fa_icon(item[:icon_name], text: item[:text], type: item[:type]),
       link: request.params.merge(
           checked_in: item[:checked_in],
           started: item[:started],
           unreconciled: item[:unreconciled],
           problem: item[:problem],
           filter: {search: ''},
           page: nil
       ),
       active: params[:checked_in]&.to_boolean == item[:checked_in] &&
           params[:started]&.to_boolean == item[:started] &&
           params[:unreconciled]&.to_boolean == item[:unreconciled] &&
           params[:problem]&.to_boolean == item[:problem]}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def explore_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'Plan my effort',
         link: plan_effort_course_path(view_object.course)},
        {name: 'All-time best',
         link: best_efforts_course_path(view_object.course)}
    ]
    build_dropdown_menu('Explore', dropdown_items, button: true)
  end

  def effort_actions_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'Set data status',
         link: set_data_status_effort_path(view_object.effort),
         method: :put},
        {role: :separator},
        {name: 'Edit effort',
         link: edit_effort_path(view_object.effort)},
        {name: 'Edit times of day',
         link: edit_split_times_effort_path(view_object.effort, display_style: :military_times)},
        {name: 'Edit elapsed times',
         link: edit_split_times_effort_path(view_object.effort)},
        {role: :separator},
        {name: 'Delete effort',
         link: effort_path(view_object.effort),
         method: :delete,
         data: {confirm: 'This action cannot be undone. Proceed?'},
         class: 'text-danger'}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def person_actions_dropdown_menu(view_object)
    dropdown_items =[
        {name: 'Edit',
        link: edit_person_path(view_object.person)},
        {name: 'Merge with',
        link: merge_person_path(view_object.person)},
        {role: :separator},
        {name: 'Delete person',
        link: person_path(view_object.person),
        method: :delete,
        data: {confirm: 'This action cannot be undone. Proceed?'},
        class: 'text-danger'}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def gender_dropdown_menu(view_object)
    dropdown_items = %w(combined male female).map do |gender|
      {name: gender.titleize,
       link: request.params.merge(filter: {gender: gender}),
       active: view_object.gender_text == gender}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def spread_style_dropdown_menu(view_object)
    dropdown_items = view_object.display_style_hash.map do |style, text|
      {name: text,
       link: request.params.merge(display_style: style),
       active: view_object.display_style == style.to_s}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def event_actions_dropdown(event)
    dropdown_items = [
        {name: 'Edit event',
         link: edit_event_path(event)},
        {name: 'Establish drops',
         link: set_stops_event_path(event),
         method: :put,
         data: {confirm: 'NOTE: For every effort that is unfinished, this will flag the effort as having stopped ' +
             'at the last aid station for which times are available. Are you sure you want to proceed?'}},
        {role: :separator},
        {name: 'Export finishers list',
         link: export_finishers_event_path(event, format: :csv)},
        {name: 'Export to ultrasignup',
         link: export_to_ultrasignup_event_path(event, format: :csv)}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def event_group_actions_dropdown(view_object)
    dropdown_items = [
        {name: 'Edit group',
         link: edit_event_group_path(view_object)},
        {name: 'Add/Remove Stewards',
         link: organization_path(view_object.organization, display_style: 'stewards')},
        {role: :separator},
        {name: 'Delete all times',
         link: delete_all_times_event_group_path(view_object),
         method: :delete,
         data: {confirm: 'NOTE: This will delete all split times and time records for the entire event group. ' +
             'This action cannot be undone. Are you sure you want to go ahead?'},
         class: 'text-danger'}
    ]
    build_dropdown_menu('Edit', dropdown_items, button: true)
  end

  def split_name_dropdown(view_object)
    dropdown_items = view_object.ordered_split_names.map do |split_name|
      {name: split_name.titleize,
       link: request.params.merge(split_name: split_name.parameterize),
       active: split_name.parameterize == @presenter.split_name.parameterize}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def sub_split_kind_dropdown(view_object)
    dropdown_items = view_object.sub_split_kinds.map do |kind|
      {name: kind.titleize,
       link: request.params.merge(sub_split_kind: kind.parameterize),
       active: kind.parameterize == @presenter.sub_split_kind.parameterize}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def traffic_band_width_dropdown(view_object)
    dropdown_items = view_object.suggested_band_widths.map do |band_width|
      {name: pluralize(band_width / 1.minute, 'minute'),
       link: request.params.merge(band_width: band_width),
       active: band_width == @presenter.band_width}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def event_staging_app_page(view_object)
    (view_object.respond_to?(:display_style)) && (view_object.display_style == 'splits') ? 'splits' : 'entrants'
  end
end
