# frozen_string_literal: true

class EffortRow < SimpleDelegator
  include Rankable

  ULTRASIGNUP_STATUS_TABLE = {"Finished" => 1, "Dropped" => 2, "Not Started" => 3}.freeze

  def country_code_alpha_3
    return nil unless country_code.present?

    Carmen::Country.coded(country_code)&.alpha_3_code
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
end
