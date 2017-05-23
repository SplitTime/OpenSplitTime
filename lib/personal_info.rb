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
    [gender&.titlecase, current_age&.to_i].compact.join(', ')
  end

  def bio_historic
    [gender.try(:titlecase), age.try(:to_i)].compact.join(', ')
  end

  def full_name
    [first_name, last_name].join(' ')
  end
  alias_method :name, :full_name

  def full_name=(full_name)
    names = full_name.to_s.split
    first = names.size < 2 ? names.first : names[0..-2].join(' ')
    last = names.size < 2 ? nil : names.last
    self.first_name, self.last_name = first, last
  end
  alias_method :name=, :full_name=

  def current_age
    current_age_from_birthdate || (has_attribute?('current_age_from_efforts') ?
        attributes['current_age_from_efforts']&.round(0) : current_age_approximate)
  end

  def current_age_from_birthdate
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
