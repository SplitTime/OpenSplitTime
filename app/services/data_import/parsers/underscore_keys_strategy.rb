module DataImport::Parsers
  class UnderscoreKeysStrategy
    include DataImport::Errors
    attr_reader :errors

    def initialize(raw_data, options)
      @raw_data = raw_data
      @options = options
      @errors = []
    end

    def parse
      raw_data.map { |row| OpenStruct.new(underscore_keys(row)) }
    end

    def underscore_keys(row)
      row.transform_keys { |key| key.to_s.underscore }
    end

    private

    attr_reader :raw_data, :options
  end
end
