# frozen_string_literal: true

module DropdownHelper
  def build_dropdown_menu(title, items)
    main_active = items.any? { |item| item[:active] } ? 'active' : nil

    content_tag :li, class: main_active do
      a_tag = content_tag :a, class: 'dropdown-toggle', data: {toggle: 'dropdown'} do
        active_item = items.find { |item| item[:active] }[:name]
        string = [title, active_item].compact.join(' / ')
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
end
