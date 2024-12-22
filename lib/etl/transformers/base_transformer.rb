# frozen_string_literal: true

module Etl
  module Transformers
    class BaseTransformer
      include Etl::Errors
      attr_reader :errors

      private

      attr_reader :options

      def event
        parent if parent.is_a?(Event)
      end

      def event_group
        parent if parent.is_a?(EventGroup)
      end

      def organization
        parent if parent.is_a?(Organization)
      end

      def parent
        options[:parent]
      end

      def parent_id_attribute
        "#{parent.class.name.underscore}_id"
      end
    end
  end
end
