module ApplicationHelper

  def time_format_hhmmss(time_in_seconds)
    return '--:--:--' if time_in_seconds.nil?
    seconds = time_in_seconds % 60
    minutes = (time_in_seconds / 60) % 60
    hours = time_in_seconds / (60 * 60)
    format("%2d:%02d:%02d", hours, minutes, seconds)
  end

  def time_format_hhmm(time_in_seconds)
    return '--:--' if time_in_seconds.nil?
    minutes = (time_in_seconds / 60) % 60
    hours = time_in_seconds / (60 * 60)
    format("%2d:%02d", hours, minutes)
  end

  def time_format_minutes(time_in_seconds)
    time_in_seconds ? (time_in_seconds / 60).round(0).to_s : '--'
  end

  def day_time_format(datetime)
    datetime.strftime("%a %-l:%M%p")
  end

  def latlon_format(latitude, longitude)
    lat = latitude.nil? ? "[Unknown]" : latitude.abs.to_s + (latitude >= 0 ? "°N" : "°S")
    lon = longitude.nil? ? "[Unknown]" : longitude.abs.to_s + (longitude >= 0 ? "°E" : "°W")
    [lat, lon].join(" / ")
  end

  def elevation_format(elevation_in_meters)
    elevation_in_meters.nil? ? '[Unknown]' : (e(elevation_in_meters).round(0).to_s + ' ' + peu)
  end

  def distance_to_preferred(meters)
    Split.distance_in_preferred_units(meters, current_user)
  end

  alias_method :d, :distance_to_preferred

  def elevation_to_preferred(meters)
    Split.elevation_in_preferred_units(meters, current_user)
  end

  alias_method :e, :elevation_to_preferred

  def preferred_distance_unit(param = 'plural')
    plural = (param == 'plural') | (param == 'pl') | (param == 'p') ? true : false
    unless current_user
      return plural ? 'miles' : 'mile'
    end
    case current_user.pref_distance_unit
      when 'miles'
        plural ? 'miles' : 'mile'
      when 'kilometers'
        plural ? 'kilometers' : 'kilometer'
      else
        plural ? 'meters' : 'meter'
    end
  end

  alias_method :pdu, :preferred_distance_unit

  def preferred_elevation_unit(param = 'plural')
    plural = (param == 'plural') | (param == 'pl') | (param == 'p') ? true : false
    unless current_user
      return plural ? 'feet' : 'foot'
    end
    case current_user.pref_elevation_unit
      when 'feet'
        plural ? 'feet' : 'foot'
      when 'meters'
        plural ? 'meters' : 'meter'
      else
        plural ? 'meters' : 'meter'
    end
  end

  alias_method :peu, :preferred_elevation_unit

end
