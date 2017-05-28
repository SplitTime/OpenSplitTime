module DataImport
  class Transformer

    def initialize(parsed_data, transform_strategy_class, options)
      @parsed_data = parsed_data
      @transform_strategy_class = transform_strategy_class
      @options = options || {}
    end

    delegate :transform, :errors, to: :transform_strategy

    def transform_strategy
      @transform_strategy ||= transform_strategy_class.new(parsed_data, options)
    end

    private

    attr_reader :parsed_data, :transform_strategy_class, :options
  end
end
