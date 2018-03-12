# frozen_string_literal: true

module ETL::Extractors
  class ItsYourRaceHTMLStrategy
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
      {full_name: full_name, gender: gender, age: age, city: city, state_code: state_code, times: times}
    end

    def full_name
      runner_info.xpath('h3').text.squish
    end

    def gender
      bio.split.fourth
    end

    def age
      bio.split.first
    end

    def city
      bio.split(',').first.split[5..-1].join(' ')
    end

    def state_code
      bio.split.last
    end

    def bio
      runner_info.xpath('p').text.squish
    end

    def runner_info
      html.search('[@class*="indiv-result-name"]')
    end

    def times
      times_table.xpath('div').map { |div| times_from_div(div) }.push(['Finish', finish_time]).to_h
    end

    def times_table
      html.search('[@id="pnlSplits"]').search('[@class*="stats-panel"]')
    end

    def times_from_div(div)
      split = div.search('[@class*="title"]').first.text.squish
      time = div.search('[@class*="number"]').first.text.squish
      [split, time]
    end

    def finish_time
      html.search('[@id="pnlGunTime"]').text.squish.split.last || '--'
    end

    def validate_setup
      errors << missing_table_error unless times_table.present? && runner_info.present?
    end
  end
end
