# frozen_string_literal: true

module DocsHelper
  def build_sidebar_menu(items)
    default_topic = items.keys.first
    default_page = 1

    content_tag(:div, class: 'list-group list-group-flush') do
      items.each do |topic, pages|
        concat(content_tag(:div, topic, class: 'sidebar-heading'))
        pages.each.with_index(1) do |page, i|
          topic_matches = (params[:topic] || default_topic).downcase == topic.downcase
          page_matches = (params[:page] || default_page).to_i == i
          active = topic_matches && page_matches ? 'active' : nil
          class_text = ['list-group-item list-group-item-action bg-light', active].compact.join(' ')

          concat(link_to page, ost_remote_path(topic: topic.downcase, page: i), class: class_text)
        end
      end
    end
  end

  def ost_remote_sidebar_menu
    items = {
        'Setup' => ['Welcome', 'Your Event and Aid Station'],
        'Menu' => ['Overview', 'Live Entry', 'Review/Sync', 'Cross Check', 'Change Station', 'Logout'],
        'Usage' => ['Pro Tips']
    }

    build_sidebar_menu(items)
  end
end
