module ETL::Extractors
  class CsvFileStrategy
    include ETL::Errors

    MAX_FILE_SIZE = 500.kilobytes
    BYTE_ORDER_MARK = "\xEF\xBB\xBF".force_encoding('UTF-8')
    attr_reader :errors

    def initialize(source_data, options)
      @source_data = source_data
      @options = options
      @errors = []
      validate_setup
    end

    def extract
      return if errors.present?
      rows = SmarterCSV.process(file, remove_empty_values: false, row_sep: :auto, force_utf8: true,
                                strip_chars_from_headers: BYTE_ORDER_MARK, downcase_header: false, strings_as_keys: true)
      rows.map { |row| OpenStruct.new(row) }
    end

    private

    attr_reader :source_data, :options

    def file
      case
      when uploaded_file
        source_data.tempfile
      when source_data.is_a?(Pathname)
        File.open(source_data)
      else # Assume source_data is a real file
        source_data
      end
    end

    def uploaded_file
      source_data.is_a?(ActionDispatch::Http::UploadedFile)
    end

    def validate_setup
      errors << file_not_found_error(source_data) unless source_data
      errors << file_too_large_error(file) if source_data && file_too_large
      errors << file_type_incorrect_error(file) if source_data && file_type_incorrect
    end

    def file_too_large
      file.size > MAX_FILE_SIZE
    end

    def file_type_incorrect
      file.path.split('.').last&.downcase != 'csv'
    end
  end
end
