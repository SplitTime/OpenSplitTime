module PersonalInfo
  extend ActiveSupport::Concern

  def bio
    [gender&.titlecase, current_age&.to_i].compact.join(', ')
  end

  def bio_historic
    [gender&.titlecase, age&.to_i].compact.join(', ')
  end

  def birthday_notice
    days = days_away_from_birthday
    return nil unless days.present?

    text = case days
           when 0
             "today"
           when 1
             "tomorrow"
           when -1
             "yesterday"
           end

    text ||= days.positive? ? "#{days} days from now" : "#{days.abs} days ago"

    "Birthday #{text}"
  end

  def country
    @country ||= Carmen::Country.coded(country_code)
  end

  def current_age
    current_age_from_birthdate || (has_attribute?('current_age_from_efforts') ?
                                       attributes['current_age_from_efforts']&.round : current_age_approximate)
  end

  def current_age_from_birthdate
    birthdate && ((Time.current - birthdate.in_time_zone) / 1.year).to_i
  end

  def days_away_from_birthday
    return nil unless birthdate.present?

    current_date = Time.current.in_time_zone(home_time_zone).to_date
    closest_anniversary = birthdate.closest_anniversary(current_date)
    (closest_anniversary - current_date).to_i
  end

  def flexible_geolocation
    [city, flexible_state, flexible_country].select(&:present?).join(', ')
  end

  def full_bio
    [bio, flexible_geolocation].select(&:present?).join(' • ')
  end

  def full_name
    [first_name, last_name].select(&:present?).join(' ')
  end
  alias_method :name, :full_name

  def personal_info
    [full_name, bio, flexible_geolocation].select(&:present?).join(' – ')
  end

  def state
    @state ||= country && country.subregions.presence&.coded(state_code)
  end

  def state_and_country
    [state_name, country_name].select(&:present?).join(', ')
  end

  private

  def country_abbreviations
    {'United States' => 'US'}
  end

  def country_name
    @country_name ||= country && (country_abbreviations[country.name] || country.name)
  end

  def flexible_state
    (city || state.nil?) ? state_code : state
  end

  def flexible_country
    case
    when city.nil? && state_code.nil?
      country&.name
    when state_code && %w[US CA].include?(country_code)
      nil
    else
      country&.name
    end
  end

  def state_name
    @state_name ||= state&.name || state_code
  end
end
