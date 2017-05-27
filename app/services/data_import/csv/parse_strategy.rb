module DataImport::Csv
  class ParseStrategy

    def initialize(raw_data_rows, options)
      @raw_data_rows = raw_data_rows
      @option = options
    end

    def parse
      @parse ||= raw_data_rows.map { |row| OpenStruct.new(row) }
    end

    private

    attr_reader :raw_data_rows, :options
  end
end
