module DataImport::Readers
  class CsvFileStrategy
    include DataImport::Errors

    BYTE_ORDER_MARK = "\xEF\xBB\xBF".force_encoding('UTF-8')
    attr_reader :errors

    def initialize(file)
      @file = file
      @errors = []
    end

    def read_file
      if file
        SmarterCSV.process(file, row_sep: :auto, force_utf8: true, strip_chars_from_headers: BYTE_ORDER_MARK)
      else
        errors << file_not_found_error(file)
        nil
      end
    end

    private

    attr_reader :file
  end
end
