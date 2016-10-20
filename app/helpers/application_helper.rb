module ApplicationHelper

  def time_format_hhmmss(time_in_seconds)
    time_formatter(time_in_seconds, '%02d:%02d:%02d', 'hms', '--:--:--')
  end

  def time_format_hhmm(time_in_seconds)
    time_formatter(time_in_seconds, '%02d:%02d', 'hm', '--:--')
  end

  def time_format_xxhyymzzs(time_in_seconds)
    if hours(time_in_seconds) == 0
      time_formatter(time_in_seconds, '%02dm%02ds', 'ms', '--:--:--')
    else
      time_formatter(time_in_seconds, '%2dh%02dm%02ds', 'hms', '--:--:--')
    end
  end

  def time_format_xxhyym(time_in_seconds)
    time_formatter(time_in_seconds, '%2dh%02dm', 'hm', '--:--')
  end

  def time_format_minutes(time_in_seconds)
    if hours(time_in_seconds) == 0
      time_formatter(time_in_seconds, '%2dm', 'm', '--')
    else
      time_formatter(time_in_seconds, '%2dh%02dm', 'hm', '--')
    end
  end

  def time_formatter(time_in_seconds, format_string, time_initials, placeholder)
    return placeholder if time_in_seconds.nil?
    format_string = "(#{format_string})" if time_in_seconds.to_i < 0
    format(format_string, *time_components(time_in_seconds, time_initials))
  end

  def time_components(time_in_seconds, time_initials)
    time_initials.chars.map { |initial| time_component_map(time_in_seconds)[initial.to_sym] }
  end

  def time_component_map(time_in_seconds)
    {h: hours(time_in_seconds),
     m: minutes(time_in_seconds),
     s: seconds(time_in_seconds)}
  end

  def hours(time_in_seconds)
    time_in_seconds ? (time_in_seconds.abs / (60 * 60)).to_i : nil
  end

  def minutes(time_in_seconds)
    time_in_seconds ? ((time_in_seconds.abs / 60) % 60).to_i : nil
  end

  def seconds(time_in_seconds)
    time_in_seconds ? (time_in_seconds.abs % 60).to_i : nil
  end

  def day_time_format(datetime)
    datetime ? datetime.strftime("%a %-l:%M%p") : '--:--:--'
  end

  def day_time_format_hhmmss(datetime)
    datetime ? datetime.strftime("%a %-l:%M:%S%p") : '--:--:--'
  end

  def day_time_military_format(datetime)
    datetime ? datetime.strftime("%a %H:%M") : '--:--:--'
  end

  def day_time_military_format_hhmmss(datetime)
    datetime ? datetime.strftime("%a %H:%M:%S") : '--:--:--'
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
    number_with_delimiter(Split.distance_in_preferred_units(meters).round(1))
  end

  alias_method :d, :distance_to_preferred

  def elevation_to_preferred(meters)
    return nil unless meters
    number_with_delimiter(Split.elevation_in_preferred_units(meters).round(0))
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