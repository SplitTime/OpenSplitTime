module DataImport::Extractors
  class CsvFileStrategy
    include DataImport::Errors

    BYTE_ORDER_MARK = "\xEF\xBB\xBF".force_encoding('UTF-8')
    attr_reader :errors

    def initialize(file, options)
      @file = file
      @options = options
      @errors = []
    end

    def extract
      if file
        raw_data = SmarterCSV.process(file, row_sep: :auto, force_utf8: true, strip_chars_from_headers: BYTE_ORDER_MARK, downcase_header: false, strings_as_keys: true)
        raw_data.map { |row| OpenStruct.new(underscore_keys(row)) }
      else
        errors << file_not_found_error(file) and return nil
      end
    end

    private

    attr_reader :file, :options

    def underscore_keys(row)
      row.transform_keys(&:underscore)
    end
  end
end
