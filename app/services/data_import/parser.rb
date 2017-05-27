module DataImport
  class Parser

    def initialize(raw_data, strategy, options)
      @raw_data = raw_data
      @strategy = strategy
      @options = options || {}
    end

    def parse
      strategy.new(raw_data, options).parse
    end

    private

    attr_reader :raw_data, :strategy, :options
  end
end
