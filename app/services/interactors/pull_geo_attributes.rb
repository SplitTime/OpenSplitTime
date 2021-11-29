# frozen_string_literal: true

module Interactors
  class PullGeoAttributes
    include Interactors::Errors

    def self.perform(source, destination)
      new(source, destination).perform
    end

    def initialize(source, destination)
      @source = source
      @destination = destination
      @errors = []
    end

    def perform
      destination.country_code ||= source.country_code unless country_conflict? || source_country_mismatch?
      destination.state_code ||= source.state_code unless state_conflict? || source_state_mismatch?
      destination.city ||= source.city unless state_conflict? || source_state_mismatch?
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :source, :destination, :errors

    def country_conflict?
      [destination.country_code, source.country_code].compact.uniq.count == 2
    end

    def state_conflict?
      [destination.state_code, source.state_code].compact.uniq.count == 2 || country_conflict?
    end

    def source_country_mismatch?
      destination.state_code &&
          source_country.try(:subregions?) &&
          source_subregion_codes.exclude?(destination.state_code)
    end

    def source_state_mismatch?
      source.state_code &&
          destination_country.try(:subregions?) &&
          destination_subregion_codes.exclude?(source.state_code)
    end

    def destination_country
      Carmen::Country.coded(destination.country_code)
    end

    def source_country
      Carmen::Country.coded(source.country_code)
    end

    def destination_subregion_codes
      destination_country.subregions.map(&:code)
    end

    def source_subregion_codes
      source_country.subregions.map(&:code)
    end

    def resources
      {source: source, destination: destination}
    end

    def response_message
      errors.present? ? "Geo information from #{source} was not resolved with destination #{destination}" :
          "Geo information from #{source} was resolved and assigned to destination #{destination}"
    end
  end
end
