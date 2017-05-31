module DataImport
  class Parser

    def initialize(raw_data, parse_strategy_class, options)
      @raw_data = raw_data
      @parse_strategy_class = parse_strategy_class
      @options = options || {}
    end

    delegate :parse, :errors, to: :parse_strategy

    def parse_strategy
      @parse_strategy ||= parse_strategy_class.new(raw_data, options)
    end

    private

    attr_reader :raw_data, :parse_strategy_class, :options
  end
end
