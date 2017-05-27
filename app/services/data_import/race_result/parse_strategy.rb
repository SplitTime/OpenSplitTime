module DataImport::RaceResult
class ParseStrategy

    def initialize(raw_data, options)
      @raw_data = raw_data
      @options = options
    end

    def parse
      extract_rows.each { |row| p row }
      extract_rows.map { |row| OpenStruct.new(row) }
    end

    private

    attr_reader :raw_data, :options

    def extract_rows
      raw_data['data'].values.first.map { |data_row| attribute_pairs(data_row) }
    end

    def attribute_pairs(data_row)
      Hash[extract_headers.zip(data_row)]
    end

    def extract_headers
      array = raw_data['list']['Fields'].map { |header| header['Label'].downcase }
      array.unshift('rr_id')
      array
    end
  end
end
