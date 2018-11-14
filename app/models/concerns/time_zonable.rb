# frozen_string_literal: true

module TimeZonable
  extend ActiveSupport::Concern

  def time_zone_valid?(time_zone_string)
    time_zone_string && ActiveSupport::TimeZone[time_zone_string].present?
  end
end
