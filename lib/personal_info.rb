module PersonalInfo
  extend ActiveSupport::Concern

  included do
    has_person_name

    enum :gender, {
      male: 0,
      female: 1,
      nonbinary: 2,
    }
  end

  def bio
    [gender&.titlecase, current_age&.to_i].compact.join(", ")
  end

  def bio_historic
    bio_historic_non_obscured
  end

  def bio_historic_non_obscured
    [gender&.titlecase, age&.to_i].compact.join(", ")
  end

  def birthday_notice
    days = days_away_from_birthday
    return nil if days.blank?

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
    current_age_non_obscured
  end

  def current_age_non_obscured
    current_age_from_birthdate || (
      if has_attribute?("current_age_from_efforts")
        attributes["current_age_from_efforts"]&.round
      else
        current_age_approximate
      end)
  end

  def current_age_from_birthdate
    birthdate && ((Time.current - birthdate.in_time_zone) / 1.year).to_i
  end

  def days_away_from_birthday
    return nil if birthdate.blank?

    current_date = Time.current.in_time_zone(home_time_zone).to_date
    closest_anniversary = birthdate.closest_anniversary(current_date)
    (closest_anniversary - current_date).to_i
  end

  def flexible_geolocation
    [city, flexible_state, flexible_country].compact_blank.join(", ")
  end

  def full_bio
    [bio, flexible_geolocation].compact_blank.join(" • ")
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  alias name full_name

  def display_full_name
    obscure_name_applied? ? initials : display_full_name_non_obscured
  end

  def display_full_name_non_obscured
    full_name
  end

  def display_full_name_conditionally_obscured(user)
    obscure_name_applied_for?(user) ? initials : display_full_name_non_obscured
  end

  def display_first_name
    obscure_name_applied? ? first_initial_with_period : display_first_name_non_obscured
  end

  def display_first_name_non_obscured
    first_name
  end

  def display_first_name_conditionally_obscured(user)
    obscure_name_applied_for?(user) ? first_initial_with_period : display_first_name_non_obscured
  end

  def display_last_name
    obscure_name_applied? ? last_initial_with_period : display_last_name_non_obscured
  end

  def display_last_name_non_obscured
    last_name
  end

  def display_last_name_conditionally_obscured(user)
    obscure_name_applied_for?(user) ? last_initial_with_period : display_last_name_non_obscured
  end

  def initials
    "#{first_initial_with_period} #{last_initial_with_period}"
  end

  def name_for_slug
    obscure_name_applied? ? initials : full_name
  end

  def personal_info
    [full_name, bio, flexible_geolocation].compact_blank.join(" – ")
  end

  def state
    @state ||= country && country.subregions.presence&.coded(state_code)
  end

  def state_and_country
    [state_name_or_code, country_name_or_code].compact.join(", ")
  end

  private

  def obscure_name_applied?
    obscure_name_source&.obscure_name?
  end

  def obscure_name_applied_for?(user)
    return false if user&.authorized_to_edit?(self)

    obscure_name_applied?
  end

  def hide_age_applied?
    obscure_name_source&.hide_age?
  end

  def hide_age_applied_for?(user)
    return false if user&.authorized_to_edit?(self)

    hide_age_applied?
  end

  def obscure_name_source
    is_a?(Person) ? self : person
  end

  def first_initial_with_period
    "#{first_name&.first}."
  end

  def last_initial_with_period
    "#{last_name&.first}."
  end

  def country_abbreviations
    { "United States" => "US" }
  end

  def country_name_or_code
    country && (country_abbreviations[country.name] || country.name)
  end

  def state_name_or_code
    state_name.presence || state_code.presence
  end

  def flexible_state
    city || state.nil? ? state_code : state
  end

  def flexible_country
    if state_code.present? && country_code.in?(%w[US CA])
      nil
    else
      country&.name
    end
  end
end
