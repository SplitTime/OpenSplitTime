# frozen_string_literal: true

require 'smarter_csv'

module ETL
  module Extractors
    class CsvFileStrategy
      include ETL::Errors

      MAX_FILE_SIZE = 1.megabyte
      BYTE_ORDER_MARK = String.new("\xEF\xBB\xBF").force_encoding('UTF-8').freeze
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
        rows.map { |row| OpenStruct.new(row) if row.compact.present? }.compact
      rescue SmarterCSV::SmarterCSVException, CSV::MalformedCSVError => exception
        errors << smarter_csv_error(exception)
        []
      end

      private

      attr_reader :source_data, :options

      def file
        @file ||=
          begin
            case
            when source_data.is_a?(::ActionDispatch::Http::UploadedFile)
              File.open(source_data.tempfile.path)
            when source_data.is_a?(::Pathname)
              File.open(source_data)
            when source_data.is_a?(::File)
              source_data
            when source_data.is_a?(::ActiveStorage::Attached)
              StringIO.new(source_data.download)
            else
              errors << invalid_file_error(file)
            end
          end
      end

      def validate_setup
        errors << file_not_found_error(source_data) unless source_data
        errors << file_too_large_error(file) if source_data && file_too_large?
        errors << file_type_incorrect_error(file) if source_data && file_type_incorrect?
      end

      def file_too_large?
        file.size > MAX_FILE_SIZE
      end

      def file_type_incorrect?
        return false unless file.respond_to?(:path)

        file.path.split('.').last&.downcase != 'csv'
      end
    end
  end
end
