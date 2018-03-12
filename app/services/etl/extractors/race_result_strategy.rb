# frozen_string_literal: true

module ETL::Extractors
  class RaceResultStrategy
    include ETL::Errors
    attr_reader :errors

    def initialize(raw_data, options)
      @raw_data = raw_data
      @options = options
      @errors = []
      validate_raw_data
    end

    def extract
      extract_rows.map { |row| OpenStruct.new(row) } if errors.empty?
    end

    private

    attr_reader :raw_data, :options

    def extract_rows
      data_rows.map { |data_row| attribute_pairs(data_row) }
    end

    def attribute_pairs(data_row)
      extract_headers.zip(data_row).to_h
    end

    def extract_headers
      array = data_fields.map { |header| expression_or_section(header) }
      array.unshift('rr_id')
      array
    end

    def expression_or_section(header)
      expression, label = [header['Expression'], header['Label']].map(&:underscore)
      expression.start_with?('section') ? expression : label
    end

    def data_rows
      @data_rows ||= raw_data['data']&.values&.first
    end

    def data_fields
      @data_fields ||= raw_data['list'] && raw_data['list']['Fields']
    end

    def validate_raw_data
      errors << missing_data_error(raw_data) unless data_rows.present?
      errors << missing_fields_error(raw_data) unless data_fields.present?
    end
  end
end
