module DataImport::Parsers
  class PassThroughStrategy
    include DataImport::Errors
    attr_reader :errors

    def initialize(raw_data, options)
      @raw_data = raw_data
      @options = options
      @errors = []
    end

    def parse
      raw_data.map { |row| OpenStruct.new(row) }
    end

    private

    attr_reader :raw_data, :options
  end
end
