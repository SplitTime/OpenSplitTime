# frozen_string_literal: true

module ETL
  module Extractors
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
        {full_name: full_name, bib_number: bib_number, gender: gender, age: age, city: city, state_code: state_code, times: times, dnf: dnf?}
      end

      def full_name
        bib_and_name.split(" - ").last
      end

      def bib_number
        bib_and_name.split(" - ").first.gsub(/\D/, "")
      end

      def bib_and_name
        @bib_and_name ||= runner_info_card.xpath("div/span").text.squish
      end

      def gender
        bio.split.fourth
      end

      def age
        bio.split.third
      end

      def city
        bio.split.first.gsub(",", "")
      end

      def state_code
        bio.split.second
      end

      def bio
        @bio ||= runner_info_card.css(".runner-stats").text.squish
      end

      def runner_info_card
        @runner_info_card ||= runner_info_container.css(".card")[0]
      end

      def runner_info_container
        @runner_info_container ||= html.search('[text()*="Runner Information"]')&.first&.parent&.parent&.parent
      end

      def times
        times_card.css(".row").each_slice(2).map { |row| times_from_row(row) }.to_h
      end

      def dnf?
        records_card.text.include?("DNF")
      end

      def times_card
        runner_info_container.css(".card")[-1]
      end

      def records_card
        runner_info_container.css(".card")[-2]
      end

      def times_from_row(row)
        raw_leg = row.first.css("span").first.text
        raw_time_info = row.second.css("span").map(&:text)

        index_key = raw_leg.split(":").first.gsub(/\D/, "").to_i
        absolute_time_in = [raw_time_info[1], raw_time_info[0]].join(" ")
        absolute_time_out = [raw_time_info[3], raw_time_info[2]].join(" ")

        [index_key, [absolute_time_in, absolute_time_out]]
      end

      def validate_setup
        errors << missing_table_error unless
          runner_info_container.present? &&
          runner_info_card.present? &&
          times_card.present? &&
          records_card.present?
      end
    end
  end
end
