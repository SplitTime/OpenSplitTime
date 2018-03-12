# frozen_string_literal: true

module ETL
  class Extractor

    def initialize(source_data, extract_strategy_class, options)
      @source_data = source_data
      @extract_strategy_class = extract_strategy_class
      @options = options || {}
    end

    delegate :extract, :errors, to: :extract_strategy

    def extract_strategy
      @extract_strategy ||= extract_strategy_class.new(source_data, options)
    end

    private

    attr_reader :source_data, :extract_strategy_class, :options
  end
end
