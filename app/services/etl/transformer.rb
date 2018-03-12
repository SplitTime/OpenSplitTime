# frozen_string_literal: true

module ETL
  class Transformer

    def initialize(parsed_structs, transform_strategy_class, options)
      @parsed_structs = parsed_structs
      @transform_strategy_class = transform_strategy_class
      @options = options || {}
    end

    delegate :transform, :errors, to: :transform_strategy

    def transform_strategy
      @transform_strategy ||= transform_strategy_class.new(parsed_structs, options)
    end

    private

    attr_reader :parsed_structs, :transform_strategy_class, :options
  end
end
