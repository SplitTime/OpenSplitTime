module PersonalInfo

  def personal_info
    [full_name, bio, state_and_country].compact.split("").flatten.join(' – ')
  end

  def state_and_country
    country = Carmen::Country.coded(country_code)
    if country.nil?
      country_name = nil
      state_name = state_code
    else
      country_name = country.name
      state = country.subregions.coded(state_code)
      state_name = state.nil? ? state_code : state.name
    end
    [state_name, country_name].compact.split("").flatten.join(", ")
  end

  def bio
    return age_today if gender.nil?
    age_today.nil? ? gender.titlecase : "#{gender.titlecase}, #{age_today}"
  end

  def full_name
    [first_name,last_name].join(" ")
  end

  def age_today
    birthdate ? exact_age_today : approximate_age_today
  end

  def exact_age_today
    now = Time.now.utc.to_date
    birthdate ? years_between_dates(birthdate, now).round(0) : nil?
  end

  def years_between_dates(date1, date2)
    (date2 - date1) / 365.25
  end

end
