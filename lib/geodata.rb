# frozen_string_literal: true

class Geodata
  ALL_COUNTRIES = ::Carmen::Country.all.freeze
  PRIORITY_COUNTRY_CODES = %w[US CA].freeze
  SORTED_COUNTRIES = ALL_COUNTRIES.sort_by { |country| [PRIORITY_COUNTRY_CODES.index(country.code) || Float::INFINITY, country.name] }.freeze

  def self.serialize_country(country)
    { code: country.code,
      name: country.name,
      subregions: included_subregions(country).sort_by(&:name).map { |subregion| [subregion.code, subregion.name] }.to_h }
  end

  def self.included_subregions(country)
    case country.code
    when "US"
      country.subregions.reject { |subregion| subregion.type == "apo" }
    else
      country.subregions
    end
  end

  STANDARD_COUNTRIES_SUBREGIONS = SORTED_COUNTRIES.map { |country| serialize_country(country) }.freeze
end
