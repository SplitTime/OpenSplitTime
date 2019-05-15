# frozen_string_literal: true

module DocsHelper
  def build_sidebar_menu(presenter)
    items = presenter.items

    content_tag(:div, class: 'list-group list-group-flush') do
      items.each do |topic, attributes|
        concat(content_tag(:div, attributes[:display_topic], class: 'sidebar-heading'))
        attributes[:pages].each.with_index(1) do |page, i|
          topic_matches = presenter.topic == topic
          page_matches = presenter.page == i
          active = topic_matches && page_matches ? 'active' : nil
          class_text = ['list-group-item list-group-item-action bg-light', active].compact.join(' ')

          concat(link_to page, {controller: :visitors, action: presenter.category, topic: topic, page: i}, class: class_text)
        end
      end
    end
  end

  def path_for_category(view_object, params = {})
    send("docs_#{view_object.category}_path", params)
  end
end
