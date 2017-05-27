module DataImport
  class Transformer

    def initialize(parsed_data, strategy, options)
      @parsed_data = parsed_data
      @strategy = strategy
      @options = options || {}
    end

    def transform
      strategy.new(parsed_data, options).transform
    end

    private

    attr_reader :parsed_data, :strategy, :options
  end
end
