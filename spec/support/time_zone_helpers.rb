module TimeZoneHelpers

  def time_in_zone(event, time_string)
    ActiveSupport::TimeZone[event.home_time_zone].parse(time_string)
  end
end
