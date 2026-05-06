class EffortRow < SimpleDelegator
  include Rankable

  ULTRASIGNUP_STATUS_TABLE = { "Finished" => 1, "Dropped" => 2, "Not Started" => 3 }.freeze

  def country_code_alpha_3
    return nil if country_code.blank?

    ::Carmen::Country.coded(country_code)&.alpha_3_code
  end

  def country_code_ioc
    return nil if country_code.blank?

    ::NormalizeCountry.convert(country_code, to: :ioc)
  end

  def effort
    __getobj__
  end

  def final_lap_split_name
    multiple_laps? ? "#{final_split_name} Lap #{final_lap}" : final_split_name
  end

  def final_day_and_time
    final_absolute_time&.in_time_zone(home_time_zone)
  end

  alias final_absolute_time_local final_day_and_time

  def ultrasignup_finish_status
    ULTRASIGNUP_STATUS_TABLE[effort_status] || "#{name} (id: #{id}, bib: #{bib_number}) is in progress"
  end

  # Display-only birthday phrasing for the finish-line card. Anchors on the
  # current calendar day in the event's home time zone — the assumption is
  # that the race director is reading this as the runner crosses the line,
  # so "today/yesterday/tomorrow" is relative to that moment, not to when
  # the effort started. Returns nil outside ±5 days so the view doesn't
  # have to gate on it.
  def birthday_notice
    days = days_away_from_birthday
    return nil if days.blank? || days.abs > 5

    today = Time.current.in_time_zone(home_time_zone).to_date
    text = case days
           when 0 then "today"
           when 1 then "tomorrow"
           when -1 then "yesterday"
           when 2..5 then "next #{(today + days).strftime('%A')}"
           when -5..-2 then "last #{(today + days).strftime('%A')}"
           end

    "Birthday #{text}"
  end

  def birthday_today?
    days_away_from_birthday&.zero? == true
  end
end
