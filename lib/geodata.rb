class Geodata

  def self.standard_countries_subregions
    serialize_countries(sorted_countries(%w(US CA)))
  end

  def self.serialize_countries(countries)
    countries.map { |country| serialize_country(country) }
  end

  def self.serialize_country(country)
    {code: country.code,
     name: country.name,
     subregions: included_subregions(country).sort_by(&:name).map { |subregion| [subregion.code, subregion.name] }.to_h}
  end

  def self.included_subregions(country)
    case country.code
    when 'US'
      country.subregions.reject { |subregion| subregion.type == 'apo' }
    else
      country.subregions
    end
  end

  def self.sorted_countries(priority = [])
    all_countries.sort_by { |country| [priority.index(country.code) || Float::INFINITY, country.name] }
  end

  def self.all_countries
    Carmen::Country.all
  end
end
