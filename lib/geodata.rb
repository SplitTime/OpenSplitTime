class Geodata
  ALL_COUNTRIES = ::Carmen::Country.all.freeze
  PRIORITY_COUNTRY_CODES = %w[US CA].freeze
  SORTED_COUNTRIES = ALL_COUNTRIES.sort_by { |country| [PRIORITY_COUNTRY_CODES.index(country.code) || Float::INFINITY, country.name] }.freeze

  def self.standard_countries_subregions
    serialize_countries(ALL_COUNTRIES(%w[US CA]))
  end

  def self.serialize_countries(countries)
    countries.map { |country| serialize_country(country) }
  end

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
end
