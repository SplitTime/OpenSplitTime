# frozen_string_literal: true

module ETL::Extractors
  class AdilasBearHTMLStrategy
    include ETL::Errors
    attr_reader :errors

    def initialize(source_data, options)
      @options = options
      @source_data = source_data
      @html = Nokogiri::HTML(source_data)
      @errors = []
      validate_setup
    end

    def extract
      OpenStruct.new(row) if errors.empty?
    end

    private

    attr_reader :html, :options

    def row
      {full_name: full_name, bib_number: bib_number, gender: gender, age: age, city: city, state_code: state_code, times: times}
    end

    def full_name
      bib_and_name.split(' - ').last
    end

    def bib_number
      bib_and_name.split(' - ').first.gsub(/\D/, '')
    end

    def bib_and_name
      runner_info.xpath('tr[2]/td[2]').text.squish
    end

    def gender
      bio.split.second
    end

    def age
      bio.split.fourth
    end

    def city
      bio.split(':').last.split(', ').first
    end

    def state_code
      bio.split(':').last.split(', ').last
    end

    def bio
      runner_info.xpath('tr[4]/td[2]').text.squish
    end

    def runner_info
      html.search('[text()*="Runner Information"]')&.first&.parent&.parent&.parent
    end

    def times
      times_table.xpath('tr')[2..-1].map { |tr| times_from_tr(tr) }.to_h
    end

    def times_table
      html.search('[text()*="Leg Length"]')&.first&.parent&.parent&.parent
    end

    def times_from_tr(tr)
      cells = tr.xpath('td').map { |td| td.text.squish }
      [cells[0].split(':').first.gsub(/\D/, '').to_i, [cells[1..2].join(' '), cells[3..4].join(' ')]]
    end

    def validate_setup
      errors << missing_table_error unless times_table.present? && runner_info.present?
    end
  end
end
