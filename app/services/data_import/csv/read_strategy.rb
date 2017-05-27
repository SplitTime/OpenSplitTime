module DataImport::Csv
  class ReadStrategy
    BYTE_ORDER_MARK = "\xEF\xBB\xBF".force_encoding('UTF-8')

    def initialize(file_path)
      @file_path = file_path
    end

    def read_file
      SmarterCSV.process(file_path, row_sep: :auto, force_utf8: true, strip_chars_from_headers: BYTE_ORDER_MARK)
    end

    private

    attr_reader :file_path
  end
end
