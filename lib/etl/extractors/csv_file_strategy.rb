# frozen_string_literal: true

require "smarter_csv"
require "csv"

module ETL
  module Extractors
    class CsvFileStrategy
      include ETL::Errors

      MAX_FILE_SIZE = 2.megabytes
      BYTE_ORDER_MARK = String.new("\xEF\xBB\xBF").force_encoding("UTF-8").freeze
      IMPORT_OPTIONS = {
        col_sep: ",",
        downcase_header: false,
        duplicate_header_suffix: nil,
        force_utf8: true,
        remove_empty_values: false,
        row_sep: :auto,
        strip_chars_from_headers: BYTE_ORDER_MARK,
        strings_as_keys: true,
      }.freeze

      attr_reader :errors

      def initialize(source_data, options)
        @source_data = source_data
        @options = options
        @errors = []
        validate_setup
      end

      def extract
        return if errors.present?

        rows = SmarterCSV.process(file, IMPORT_OPTIONS)
        rows.map do |row|
          if valid_csv_row?(row)
            OpenStruct.new(row)
          end
        end.compact
      rescue SmarterCSV::SmarterCSVException, ::CSV::MalformedCSVError => e
        errors << smarter_csv_error(e)
        []
      end

      private

      attr_reader :source_data, :options

      def file
        @file ||=
          begin
            if source_data.is_a?(::ActionDispatch::Http::UploadedFile)
              File.open(source_data.tempfile.path)
            elsif source_data.is_a?(::Pathname)
              File.open(source_data)
            elsif source_data.is_a?(::File)
              source_data
            elsif source_data.is_a?(::ActiveStorage::Attached) || source_data.is_a?(::ActiveStorage::Attachment)
              StringIO.new(source_data.download, "r:utf-8")
            else
              errors << invalid_file_error(source_data)
            end
          end
      end

      # @param [Hash] row
      # @return [Boolean]
      def valid_csv_row?(row)
        return false unless row.present?
        # Reject HTML rows
        first_value = row.first.last.to_s
        return false if first_value.start_with?("<") && first_value.end_with?(">")

        true
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

        file.path.split(".").last&.downcase != "csv"
      end
    end
  end
end
