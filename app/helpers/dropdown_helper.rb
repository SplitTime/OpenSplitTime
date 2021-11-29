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
        {name: 'Reconcile',
         link: reconcile_event_group_path(view_object.event_group),
         active: action_name == 'reconcile'},
        {name: 'Roster',
         link: roster_event_group_path(view_object.event_group),
         active: action_name == 'roster' && !params[:problem]},
        {name: 'Problems',
         link: roster_event_group_path(view_object.event_group, problem: true),
         active: action_name == 'roster' && params[:problem]},
        {name: 'Settings',
         link: event_group_path(view_object.event_group, force_settings: true),
         active: controller_name == 'event_groups' && action_name == 'show'},
        {name: 'Stats',
         link: stats_event_group_path(view_object.event_group),
         active: controller_name == 'event_groups' && action_name == 'stats'},
        {name: 'Finish Line',
         link: finish_line_event_group_path(view_object.event_group),
         active: controller_name == 'event_groups' && action_name == 'finish_line'},
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
        {name: 'Full',
         link: spread_event_path(view_object.event),
         active: action_name == 'spread'},
        {name: 'Summary',
         link: summary_event_path(view_object.event),
         active: action_name == 'summary' && !(params[:finished] == 'true')},
        {name: 'Finishers',
         link: summary_event_path(view_object.event, finished: true),
         active: action_name == 'summary' && params[:finished] == 'true'},
        {name: 'Podium',
         link: podium_event_path(view_object.event),
         active: action_name == 'podium'},
        {name: 'Follow',
         link: follow_event_group_path(view_object.event_group),
         active: action_name == 'follow'},
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

  def check_in_filter_dropdown
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

  def raw_time_filter_dropdown
    items = [{icon_name: 'hand-paper', type: :solid, text: 'Stopped', stopped: true, reviewed: nil, matched: nil},
             {icon_name: 'cloud-download-alt', type: :solid, text: 'Reviewed', stopped: nil, reviewed: true, matched: nil},
             {icon_name: 'cloud-upload-alt', type: :solid, text: 'Unreviewed', stopped: nil, reviewed: false, matched: nil},
             {icon_name: 'check-square', type: :solid, text: 'Matched', stopped: nil, reviewed: nil, matched: true},
             {icon_name: 'square', type: :solid, text: 'Unmatched', stopped: nil, reviewed: nil, matched: false},
             {icon_name: 'asterisk', type: :solid, text: 'All', stopped: nil, reviewed: nil, matched: nil}]

    dropdown_items = items.map do |item|
      {name: fa_icon(item[:icon_name], text: item[:text], type: item[:type]),
       link: request.params.merge(
           stopped: item[:stopped],
           reviewed: item[:reviewed],
           matched: item[:matched],
           page: nil
       ),
       active: params[:stopped]&.to_boolean == item[:stopped] &&
           params[:reviewed]&.to_boolean == item[:reviewed] &&
           params[:matched]&.to_boolean == item[:matched]}
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def summary_filter_dropdown
    items = [{text: 'All', finished: nil},
             {text: 'Finished', finished: true},
             {text: 'Unfinished', finished: false}]

    dropdown_items = items.map do |item|
      {name: item[:text],
       link: request.params.merge(finished: item[:finished], page: nil),
       active: params[:finished]&.to_boolean == item[:finished]}
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
        {name: 'Set Data Status',
         link: set_data_status_effort_path(view_object.effort),
         method: :patch},
        {role: :separator},
        {name: 'Edit Times of Day',
         link: edit_split_times_effort_path(view_object.effort, display_style: :military_time)},
        {name: 'Edit Dates and Times',
         link: edit_split_times_effort_path(view_object.effort, display_style: :absolute_time_local)},
        {name: 'Edit Elapsed Times',
         link: edit_split_times_effort_path(view_object.effort, display_style: :elapsed_time)},
        {role: :separator},
        {name: 'Edit Entrant',
         link: edit_effort_path(view_object.effort)},
        {name: 'Rebuild Times',
         link: rebuild_effort_path(view_object.effort),
         method: :patch,
         data: {confirm: "This will delete all split times and attempt to rebuild them from the " +
             "#{pluralize(view_object.raw_times_count, 'raw time')} related to this effort. This action cannot be undone. Proceed?"},
         visible: view_object.multiple_laps? && view_object.raw_times_count.positive?},
        {role: :separator},
        {name: 'Delete Entrant',
         link: effort_path(view_object.effort),
         method: :delete,
         data: {confirm: 'This action cannot be undone. Proceed?'},
         class: 'text-danger'}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def event_series_actions_dropdown_menu(view_object)
    dropdown_items = [
        {name: 'Edit',
         link: edit_event_series_path(view_object.event_series)},
        {role: :separator},
        {name: 'Delete event series',
         link: event_series_path(view_object.event_series),
         method: :delete,
         data: {confirm: 'This action cannot be undone. Proceed?'},
         class: 'text-danger'}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def person_actions_dropdown_menu(view_object)
    dropdown_items = [
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
       link: request.params.merge(filter: {gender: gender}, page: nil),
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
        {name: 'Edit/Delete Event',
         link: edit_event_path(event)},
        {name: 'Establish Drops',
         link: set_stops_event_path(event),
         method: :put,
         data: {confirm: 'NOTE: For every effort that is unfinished, this will flag the effort as having stopped ' +
             'at the last aid station for which times are available. Are you sure you want to proceed?'}},
        {name: 'Shift start time',
         link: edit_start_time_event_path(event),
         visible: current_user.admin?},
        {role: :separator},
        {name: 'Export Finishers List',
         link: export_event_path(event, format: :csv, export_format: :finishers)},
        {name: 'Export to ITRA',
         link: export_event_path(event, format: :csv, export_format: :itra)},
        {name: 'Export to Ultrasignup',
         link: export_event_path(event, format: :csv, export_format: :ultrasignup)}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def event_group_actions_dropdown(view_object)
    dropdown_items = [
        {name: 'Edit/Delete Group',
         link: edit_event_group_path(view_object)},
        {name: 'Duplicate Group',
         link: new_duplicate_event_group_path(existing_id: view_object.event_group.id)},
        {role: :separator},
        {name: 'Add/Remove Stewards',
         link: organization_path(view_object.organization, display_style: 'stewards')}
    ]
    build_dropdown_menu('Group Actions', dropdown_items, button: true)
  end

  def roster_actions_dropdown(view_object)
    dropdown_items = [
        {name: 'Reconcile efforts',
         link: reconcile_event_group_path(view_object.event_group)},
        {name: 'Set data status',
         link: set_data_status_event_group_path(view_object.event_group),
         method: :patch}
    ]
    build_dropdown_menu('Actions', dropdown_items, button: true)
  end

  def split_name_dropdown(view_object, param: :parameterized_split_name)
    dropdown_items = view_object.ordered_split_names.map do |split_name|
      {name: split_name,
       link: request.params.merge(param => split_name.parameterize),
       active: split_name.parameterize == view_object.split_name&.parameterize}
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def split_name_filter_dropdown(view_object, param: :parameterized_split_name)
    default_item_filter = (request.params[:filter] || {}).except(param)
    default_item = {name: 'All Splits',
                    link: request.params.merge(filter: default_item_filter, page: nil),
                    active: view_object.split_name.parameterize == 'all-splits'}
    dropdown_items = view_object.ordered_split_names.map do |split_name|
      {name: split_name,
       link: request.params.deep_merge(filter: {param => split_name.parameterize}, page: nil),
       active: split_name.parameterize == view_object.split_name.parameterize}
    end
    dropdown_items.unshift(default_item)

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def prior_next_nav_button(view_object, prior_or_next, param: :parameterized_split_name)
    icon_name = prior_or_next == :prior ? 'caret-left' : 'caret-right'
    target = view_object.send("#{prior_or_next}_#{param}")
    merge_param = target.present? ? {param => target} : {}
    titleized_prior_or_next = prior_or_next.to_s.titleize
    tooltip_title = "#{titleized_prior_or_next} [Ctrl-#{titleized_prior_or_next.first}]"

    content_tag :span, data: {controller: :navigation} do
      link_to fa_icon(icon_name, class: 'fa-lg'),
              request.params.merge(merge_param),
              id: "#{prior_or_next}-button",
              class: 'btn btn-outline-secondary has-tooltip',
              data: {action: 'keyup@document->navigation#evaluateKeyup',
                     target: "navigation.#{prior_or_next}Button",
                     toggle: 'tooltip',
                     placement: :bottom,
                     'original-title' => tooltip_title},
              disabled: target.blank?
    end
  end

  def sub_split_kind_dropdown(view_object)
    dropdown_items = view_object.sub_split_kinds.map do |kind|
      {name: kind.titleize,
       link: request.params.merge(sub_split_kind: kind.parameterize),
       active: kind.parameterize == view_object.sub_split_kind.parameterize}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def traffic_band_width_dropdown(view_object)
    dropdown_items = view_object.suggested_band_widths.map do |band_width|
      {name: pluralize(band_width / 1.minute, 'minute'),
       link: request.params.merge(band_width: band_width),
       active: band_width == view_object.band_width}
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def event_staging_app_page(view_object)
    (view_object.respond_to?(:display_style)) && (view_object.display_style == 'splits') ? 'splits' : 'entrants'
  end
end
