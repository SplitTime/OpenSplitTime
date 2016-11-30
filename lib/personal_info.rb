module PersonalInfo
  extend ActiveSupport::Concern

  def personal_info
    [full_name, bio, state_and_country].compact.join(' – ')
  end

  def city_state_and_country
    [city, state_and_country].compact.join(', ')
  end

  def state_and_country
    [state_name, country_name].compact.join(', ')
  end

  def country
    @country ||= Carmen::Country.coded(country_code)
  end

  def country_name
    @country_name ||= country && (country_abbreviations[country.name] || country.name)
  end

  def state
    @state ||= country && country.subregions.coded(state_code)
  end

  def state_name
    @state_name ||= (state && state.name) || state_code
  end

  def country_abbreviations
    {'United States' => 'US'}
  end

  def bio
    current_age = try(:participant_age) || age_today
    [gender.try(:titlecase), current_age.try(:to_i)].compact.join(', ')
  end

  def bio_historic
    [gender.try(:titlecase), age.try(:to_i)].compact.join(', ')
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def age_today
    birthdate ? exact_age_today : approximate_age_today
  end

  def exact_age_today
    birthdate && TimeDifference.between(birthdate, Time.now.utc.to_date).in_years.round(0)
  end

  def full_bio
    [bio, city_state_and_country].compact.join(' • ')
  end

  module ClassMethods
    def exact_ages_today # Returns a hash of {resource.id => age today} ignoring any resource without a birthdate
      now = Time.now.utc.to_date
      birthdate_hash = Hash[self.where.not(birthdate: nil).pluck(:id, :birthdate)]
      Hash[birthdate_hash.map { |id, birthdate| [id, TimeDifference.between(birthdate, now).in_years.round(0)] }]
    end
  end
end