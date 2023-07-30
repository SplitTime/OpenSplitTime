# frozen_string_literal: true

require_relative "parse_methods"

# Inspired by and largely copied from the font_awesome5_rails gem
module FontAwesome6
  module Parsers
    class IconParser
      include ActionView::Helpers::TagHelper
      include ParseMethods

      def initialize(icon_name, options = {})
        @icon_name = icon_name
        @options = options
        @type = options[:type]
        @text = options[:text]
        @right = options[:right] == true
        @size = options[:size]
        @attrs = options.except(:text, :type, :class, :icon, :animation, :size, :right)
      end

      def render
        return icon_content_tag if text.blank?

        right ? (text_content_tag + icon_content_tag) : (icon_content_tag + text_content_tag)
      end

      private

      attr_reader :icon_name, :type, :options, :text, :right, :size, :attrs

      def classes
        @classes ||= parse_classes
      end

      def sizes
        @sizes ||= size.blank? ? "" : arr_with_fa(size).uniq.compact.join(" ")
      end

      def parse_classes
        tmp = []
        tmp << icon_type(type)
        tmp += arr_with_fa(icon_name)
        tmp += arr_with_fa(size) if size.present?
        tmp.uniq.compact.join(" ")
      end

      def icon_content_tag
        content_tag(:i, nil, class: classes, **attrs)
      end

      def text_content_tag
        fa6_text_css_class = right ? 'fa6-text-r' : 'fa6-text'
        content_tag(
          :span, @text,
          class: "#{fa6_text_css_class}#{' ' unless sizes.blank?}#{sizes}",
          style: @style,
        )
      end
    end
  end
end