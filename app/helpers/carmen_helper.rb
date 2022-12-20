# frozen_string_literal: true

module CarmenHelper
  SORTED_COUNTRIES_FOR_SELECT = Geodata::SORTED_COUNTRIES.map { |country| [country.name, country.code] }

  def carmen_country_select(model, field, args = {})
    prompt = args.delete(:prompt) || "Please select a country"
    options = { include_blank: prompt }.merge(args)

    select(model,
           field,
           SORTED_COUNTRIES_FOR_SELECT,
           options,
           { class: "form-control",
             data: { "carmen-target" => "countrySelect",
                     action: "change->carmen#getSubregions" } })
  end

  def carmen_subregion_select(model, field, country, args = {})
    prompt = args.delete(:prompt)
    options = { include_blank: prompt }.merge(args)
    subregion_table = country.present? ? carmen_subregions(country) : []

    select(model,
           field,
           subregion_table,
           options,
           { class: "form-control",
             disabled: country.blank? })
  end

  private

  def carmen_subregions(country)
    Geodata.included_subregions(country).map { |subregion| [subregion.name, subregion.code] }
  end
end
