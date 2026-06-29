module CrewAccessHelper
  # Formats a time as abbreviated day + 24-hour time in the given zone, e.g. "Sat 14:22".
  def day_and_military(time, home_time_zone)
    return if time.nil?

    l(time.in_time_zone(home_time_zone), format: :day_and_military)
  end
end
