module ApplicationHelper

  def time_format_hhmmss(time_in_seconds)
    return '--:--:--' if time_in_seconds.nil?
    if time_in_seconds < 0
      time_in_seconds = time_in_seconds.abs
      seconds = time_in_seconds % 60
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("(%02d:%02d:%02d)", hours, minutes, seconds)
    else
      seconds = time_in_seconds % 60
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("%02d:%02d:%02d", hours, minutes, seconds)
    end
  end

  def time_format_hhmm(time_in_seconds)
    return '--:--' if time_in_seconds.nil?
    if time_in_seconds < 0
      time_in_seconds = time_in_seconds.abs
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("(%2d:%02d)", hours, minutes)
    else
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("%2d:%02d", hours, minutes)
    end
  end

  def time_format_xxhyym(time_in_seconds)
    return '--:--' if time_in_seconds.nil?
    if time_in_seconds < 0
      time_in_seconds = time_in_seconds.abs
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("(%2dh%02dm)", hours, minutes)
    else
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("%2dh%02dm", hours, minutes)
    end
  end

  def time_format_xxhyymzzs(time_in_seconds)
    return '--:--:--' if time_in_seconds.nil?
    if time_in_seconds < 0
      time_in_seconds = time_in_seconds.abs
      seconds = time_in_seconds % 60
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("(%2dh%02dm%02ds)", hours, minutes, seconds)
    else
      seconds = time_in_seconds % 60
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)
      format("%2dh%02dm%02ds", hours, minutes, seconds)
    end
  end

  def time_format_minutes(time_in_seconds)
    return '--' if time_in_seconds.nil?
    if (time_in_seconds / 60).round(0) < 0
      "(#{(time_in_seconds.abs / 60).round(0).to_s}m)"
    else
      "#{(time_in_seconds / 60).round(0).to_s}m"
    end
  end

  def day_time_format(datetime)
    datetime ? datetime.strftime("%a %-l:%M%p") : '--:--:--'
  end

  def day_time_military_format(datetime)
    datetime ? datetime.strftime("%a %H:%M") : '--:--:--'
  end

  def day_time_full_format(datetime)
    datetime ? datetime.strftime("%B %-d, %Y %l:%M%p") : '--:--:--'
  end

  def latlon_format(latitude, longitude)
    lat = latitude.nil? ? "[Unknown]" : latitude.abs.to_s + (latitude >= 0 ? "°N" : "°S")
    lon = longitude.nil? ? "[Unknown]" : longitude.abs.to_s + (longitude >= 0 ? "°E" : "°W")
    [lat, lon].join(" / ")
  end

  def elevation_format(elevation_in_meters)
    return nil unless elevation_in_meters
    elevation_in_meters.nil? ? '[Unknown]' : (e(elevation_in_meters).to_s + ' ' + peu)
  end

  def distance_to_preferred(meters)
    number_with_delimiter(Split.distance_in_preferred_units(meters, current_user).round(1))
  end

  alias_method :d, :distance_to_preferred

  def elevation_to_preferred(meters)
    return nil unless meters
    number_with_delimiter(Split.elevation_in_preferred_units(meters, current_user).round(0))
  end

  alias_method :e, :elevation_to_preferred

  def preferred_distance_unit(param = 'plural')
    unless current_user
      return case param
               when 'short'
                 'mi'
               when 'singular'
                 'mile'
               else
                 'miles'
             end
    end
    case current_user.pref_distance_unit
      when 'miles'
        case param
          when 'short'
            'mi'
          when 'singular'
            'mile'
          else
            'miles'
        end
      when 'kilometers'
        case param
          when 'short'
            'km'
          when 'singular'
            'kilometer'
          else
            'kilometers'
        end
      else
        case param
          when 'short'
            'm'
          when 'singular'
            'meter'
          else
            'meters'
        end
    end
  end

  alias_method :pdu, :preferred_distance_unit

  def preferred_elevation_unit(param = 'plural')
    plural = param == 'plural' ? true : false
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

def base_name(split_id)
  Split.find(split_id).base_name
end
