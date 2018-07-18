# frozen_string_literal: true

module DropdownHelper
  def build_dropdown_menu(title, items)
    main_active = items.any? { |item| item[:active] } ? 'active' : nil

    content_tag :li, class: main_active do
      a_tag = content_tag :a, class: 'dropdown-toggle', data: {toggle: 'dropdown'} do
        active_name = items.find { |item| item[:active] }&.dig(:name)
        string = [title, active_name].compact.join(' / ')
        span = content_tag(:span, '', class: 'caret')
        [string, '&nbsp;', span].join.html_safe
      end

      ul_tag = content_tag :ul, class: 'dropdown-menu' do
        html_items = items.map do |item|
          active = item[:active] ? 'active' : nil
          content_tag :li, class: active do
            (link_to item[:name], item[:link]).html_safe
          end
        end
        html_items.join.html_safe
      end

      a_tag + ul_tag
    end
  end

  def live_dropdown_menu(view_object)
    build_dropdown_menu('Live', [
      {
        name: 'Live Entry',
        link: live_entry_live_event_group_path(view_object.event_group),
        active: action_name == 'live_entry',
        visible: true
      },
      {
        name: 'Drops',
        link: drop_list_event_path(view_object.event),
        active: action_name == 'drop_list',
        visible: true
      },
      {
        name: 'Progress',
        link: progress_report_live_event_path(view_object.event),
        active: action_name == 'progress_report',
        visible: true
      },
      {
        name: 'Aid Stations',
        link: aid_station_report_live_event_path(view_object.event),
        active: action_name == 'aid_station_report',
        visible: true
      }
    ])
  end
end
