module ApplicationHelper

  def time_format_hhmmss(time_in_seconds)
    return "" if time_in_seconds.nil?
    seconds = time_in_seconds % 60
    minutes = (time_in_seconds / 60) % 60
    hours = time_in_seconds / (60 * 60)

    format("%2d:%02d:%02d", hours, minutes, seconds)
  end

  def time_format_hhmm(time_in_seconds)
    return "" if time_in_seconds.nil?
    minutes = (time_in_seconds / 60) % 60
    hours = time_in_seconds / (60 * 60)

    format("%2d:%02d", hours, minutes)
  end

  def day_time_format(datetime)
    datetime.strftime("%a %-l:%M%p")
  end

  def latlon_format(latitude, longitude)
    if latitude.nil?
      result = "[Unknown]"
    else
      result = latitude.abs.to_s + (latitude >= 0 ? "°N" : "°S")
    end
    result = result + " / "
    if longitude.nil?
      result = result + "[Unknown]"
    else
      result = result + longitude.abs.to_s + (longitude >= 0 ? "°E" : "°W")
    end
  end

  def elevation_format(elevation_in_meters)
    elevation_in_meters.nil? ? '[Unknown]' : (e(elevation_in_meters).round(0).to_s + ' ' + peu('plural'))
  end

  def distance_in_preferred_units(distance_in_meters)
    return distance_in_meters.meters.to.miles.value unless current_user
    case
      when current_user.pref_distance_unit == 'miles'
        distance_in_meters.meters.to.miles.value
      when current_user.pref_distance_unit == 'kilometers'
        distance_in_meters.meters.to.kilometers.value
      else
        distance_in_meters
    end
  end

  alias_method :d, :distance_in_preferred_units

  def elevation_in_preferred_units(elevation_in_meters)
    return elevation_in_meters.meters.to.feet.value unless current_user
    case
      when current_user.pref_elevation_unit == 'feet'
        elevation_in_meters.meters.to.feet.value
      when current_user.pref_elevation_unit == 'meters'
        elevation_in_meters
      else
        elevation_in_meters
    end
  end

  alias_method :e, :elevation_in_preferred_units

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
