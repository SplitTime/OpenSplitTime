module ApplicationHelper

  def state_and_country_of(resource)
    country = Carmen::Country.coded(resource.country_code)
    if country.nil?
      country_name = nil
      state_name = resource.state_code
    else
      country_name = country.name
      state = country.subregions.coded(resource.state_code)
      state_name = state.nil? ? resource.state_code : state.name
    end
    [state_name, country_name].compact.split("").flatten.join(", ")
  end

  def time_format_of(total_seconds)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

end
