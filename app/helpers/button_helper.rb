# frozen_string_literal: true

module ButtonHelper
    def build_button_group(items, options = {})
        content_tag :div, class: ['btn-group', options[:class]].join(' ') do
            items.select { |item| item[:visible] }.each do |item|
                disabled = item[:disabled] ? 'disabled' : ''
                concat link_to item[:name], item[:link], {
                    class: "btn #{options[:button_class]} #{disabled}",
                    role: item[:role]
                }.merge(item.fetch(:item_options, {}))
            end
        end
    end

    def display_style_button_group(view_object, styles = {}, options = {})
        items = styles.map{ |style, name| {
                name: name,
                link: request.params.merge(display_style: style.to_s),
                disabled: view_object.display_style == style.to_s,
                visible: true
        }}
        build_button_group(items, options)
    end
end