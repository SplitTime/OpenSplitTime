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
        items.select { |item| item[:visible] }.each do |item|
          if item[:role] == :separator
            concat content_tag(:div, class: 'dropdown-divider')
          else
            active = item[:active] ? 'active' : nil
            concat link_to item[:name], item[:link], {
              class: "dropdown-item #{active}",
              role: item[:role]
            }.merge(item.fetch(:item_options, {}))
          end
        end
      }
    end
  end

  def admin_dropdown_menu(view_object)
    build_dropdown_menu('Admin', [
        {name: 'Staging',
         link: "#{event_staging_app_path(view_object.event)}#/#{event_staging_app_page(view_object)}",
         active: action_name == 'app',
         visible: true},
        {name: 'Roster',
         link: roster_event_group_path(view_object.event_group),
         active: action_name == 'roster' && !params[:problem],
         visible: true},
        {name: 'Problems',
         link: roster_event_group_path(view_object.event_group, problem: true),
         active: action_name == 'roster' && params[:problem],
         visible: true},
        {name: 'Settings',
         link: event_group_path(view_object.event_group, force_settings: true),
         active: controller_name == 'event_groups' && action_name == 'show',
         visible: true}
    ], class: 'nav-item')
  end

  def live_dropdown_menu(view_object)
    build_dropdown_menu('Live', [
        {name: 'Time Entry',
         link: live_entry_live_event_group_path(view_object.event_group),
         active: action_name == 'live_entry',
         visible: view_object.available_live},
        {name: 'Drops',
         link: drop_list_event_path(view_object.event),
         active: action_name == 'drop_list',
         visible: true},
        {name: 'Progress',
         link: progress_report_live_event_path(view_object.event),
         active: action_name == 'progress_report',
         visible: true},
        {name: 'Aid Stations',
         link: aid_station_report_live_event_path(view_object.event),
         active: action_name == 'aid_station_report',
         visible: true},
        {name: 'Aid Detail',
         link: aid_station_detail_live_event_path(view_object.event),
         active: action_name == 'aid_station_detail',
         visible: true}
    ], class: 'nav-item')
  end

  def results_dropdown_menu(view_object)
    build_dropdown_menu('Results', [
        {name: 'List',
         link: event_path(view_object.event),
         active: controller_name == 'events' && action_name == 'show',
         visible: true},
        {name: 'Spread',
         link: spread_event_path(view_object.event),
         active: action_name == 'spread',
         visible: true},
        {name: 'Summary',
         link: summary_event_path(view_object.event),
         active: action_name == 'summary',
         visible: true},
        {name: 'Podium',
         link: podium_event_path(view_object.event),
         active: action_name == 'podium',
         visible: true},
        {name: 'Traffic',
         link: traffic_event_group_path(view_object.event_group),
         active: action_name == 'traffic',
         visible: true}
    ], class: 'nav-item')
  end

  def raw_times_dropdown_menu(view_object)
    build_dropdown_menu('Raw Times', [
        {name: 'List',
         link: raw_times_event_group_path(view_object.event_group),
         active: action_name == 'raw_times',
         visible: true},
        {name: 'Splits',
         link: split_raw_times_event_group_path(view_object.event_group),
         active: action_name == 'split_raw_times',
         visible: true}
    ], class: 'nav-item')
  end

  def check_in_filter_dropdown_menu(items)
    dropdown_items = items.map do |item|
      {
          name: content_tag(:i, nil, class: "glyphicon glyphicon-#{item[:icon]}") + ' ' + item[:name],
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
              params[:problem]&.to_boolean == item[:problem],
          visible: true
      }
    end
    build_dropdown_menu(nil, dropdown_items, class: 'pull-right', button: true)
  end

  def explore_dropdown_menu(view_object)
    dropdown_items = [{name: 'Plan my effort',
                       link: plan_effort_course_path(view_object.course),
                       visible: true},
                      {name: 'All-time best',
                       link: best_efforts_course_path(view_object.course),
                       visible: true}]
    build_dropdown_menu('Explore', dropdown_items, button: true)
  end

  def effort_actions_dropdown_menu(view_object)
    dropdown_items =
        [{name: 'Effort',
          link: edit_effort_path(view_object.effort),
          visible: true},
         {name: 'Times of day',
          link: edit_split_times_effort_path(view_object.effort, display_style: :military_times),
          visible: true},
         {name: 'Elapsed times',
          link: edit_split_times_effort_path(view_object.effort),
          visible: true},
         {name: '',
         link: '#',
         visible: true,
         role: :separator},
         {name: 'Delete effort',
         link: effort_path(view_object.effort),
         visible: true,
         item_options: {method: :delete, data: {confirm: 'This action cannot be undone. Proceed?'}}}]
    build_dropdown_menu('Edit', dropdown_items, button: true)
  end

  def event_staging_app_page(view_object)
    (view_object.respond_to?(:display_style)) && (view_object.display_style == 'splits') ? 'splits' : 'entrants'
  end
end
