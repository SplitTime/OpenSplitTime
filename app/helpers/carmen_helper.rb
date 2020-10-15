# frozen_string_literal: true

module CarmenHelper
  def carmen_country_select(model, field, args)
    priority = args[:priority]
    prompt = "Please select a country"
    country_table = Geodata.sorted_countries(priority).map { |country| [country.name, country.code] }
    country_table.unshift([prompt, nil])

    select(model, field, country_table, {}, {class: "form-control",
                                             data: {target: "carmen.countrySelect",
                                                    action: "change->carmen#getSubregions"}})
  end

  def carmen_subregion_select(model, field, country, args = {})
    prompt = args[:prompt]
    subregion_table = country.present? ? carmen_subregions(country) : []
    subregion_table.unshift([prompt, nil])

    select(model, field, subregion_table, {}, {class: "form-control", disabled: country.blank?})
  end

  private

  def carmen_subregions(country)
    Geodata.included_subregions(country).map { |subregion| [subregion.name, subregion.code] }
  end
end
