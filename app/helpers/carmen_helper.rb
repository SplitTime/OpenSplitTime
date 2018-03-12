# frozen_string_literal: true

module CarmenHelper

  def carmen_country_select(model, field, args)
    priority = args[:priority]
    prompt = args[:prompt]
    country_table = Geodata.sorted_countries(priority).map { |country| [country.name, country.code] }
    select(model, field, country_table, prompt: prompt)
  end

  def carmen_subregion_select(model, field, country)
    subregion_table = Geodata.included_subregions(country).map { |subregion| [subregion.name, subregion.code] }
    select(model, field, subregion_table)
  end
end
