# frozen_string_literal: true

module ETL::Transformers
  class BaseTransformer
    include ETL::Errors
    attr_reader :errors

    private

    attr_reader :options

    def event
      parent if parent.is_a?(Event)
    end

    def parent
      options[:parent]
    end

    def parent_id_attribute
      "#{parent.class.name.underscore}_id"
    end
  end
end
