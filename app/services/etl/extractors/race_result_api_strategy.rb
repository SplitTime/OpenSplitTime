# frozen_string_literal: true

module ETL::Extractors
  class RaceResultApiStrategy
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
      time_pairs = time_indicies.map.with_index { |time_index, i| ["time_#{i}".to_sym, data_row[time_index].gsub('Time: ', '')] }.to_h
      bib, name = data_row[1].split('. ')
      bib = bib.gsub('#', '')
      name = name.titleize
      status = data_row[2].gsub('STATUS: ', '')
      time_pairs.merge(bib: bib, name: name, status: status, rr_id: data_row[0])
    end

    def time_indicies
      @time_indicies ||= data_fields.map.with_index(1) { |header, i| time_index(header, i) }.compact
    end

    def time_index(header, i)
      i if header['expression'].include?('"Time: "')
    end

    def data_rows
      @data_rows ||= raw_data['data']&.values&.first
    end

    def data_fields
      @data_fields ||= raw_data.dig('list', 'fields')
    end

    def validate_raw_data
      errors << missing_data_error(raw_data) unless data_rows.present?
      errors << missing_fields_error(raw_data) unless data_fields.present?
    end
  end
end
