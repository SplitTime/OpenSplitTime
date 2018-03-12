# frozen_string_literal: true

module ETL
  class Loader

    def initialize(proto_records, load_strategy_class, options)
      @proto_records = proto_records
      @load_strategy_class = load_strategy_class
      @options = options || {}
    end

    delegate :load_records, :saved_records, :invalid_records, :destroyed_records,
             :ignored_records, :errors, to: :load_strategy

    def load_strategy
      @load_strategy ||= load_strategy_class.new(proto_records, options)
    end

    private

    attr_reader :proto_records, :load_strategy_class, :options
  end
end
