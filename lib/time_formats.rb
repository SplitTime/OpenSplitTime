module TimeFormats
  extend ActiveSupport::Concern

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
      time_formatter(time_in_seconds, '%02dh%02dm%02ds', 'hms', '--:--:--')
    end
  end

  def time_format_xxhyym(time_in_seconds)
    if hours(time_in_seconds) == 0
      time_formatter(time_in_seconds, '%01dm', 'm', '--:--')
    else
      time_formatter(time_in_seconds, '%01dh%02dm', 'hm', '--:--')
    end
  end

  def time_format_minutes(time_in_seconds)
    if true_minutes(time_in_seconds).to_i <= 90
      time_formatter(time_in_seconds, '%1dm', 't', '--')
    else
      time_formatter(time_in_seconds, '%1dh%02dm', 'hm', '--')
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
     t: true_minutes(time_in_seconds),
     s: seconds(time_in_seconds)}
  end

  def hours(time_in_seconds)
    time_in_seconds && (time_in_seconds.abs / (60 * 60)).to_i
  end

  def minutes(time_in_seconds)
    time_in_seconds && ((time_in_seconds.abs / 60) % 60).to_i
  end

  def true_minutes(time_in_seconds)
    time_in_seconds && (time_in_seconds.abs / 60).to_i
  end

  def seconds(time_in_seconds)
    time_in_seconds && (time_in_seconds.abs % 60).to_i
  end

  def day_time_format(datetime)
    datetime ? datetime.strftime('%a %-l:%M%p') : '--:--:--'
  end

  def day_time_format_hhmmss(datetime)
    datetime ? datetime.strftime('%a %-l:%M:%S%p') : '--:--:--'
  end

  def day_time_military_format(datetime)
    datetime ? datetime.strftime('%a %H:%M') : '--:--:--'
  end

  def day_time_military_format_hhmmss(datetime)
    datetime ? datetime.strftime('%a %H:%M:%S') : '--:--:--'
  end

  def day_time_full_format(datetime)
    datetime ? datetime.strftime('%B %-d, %Y %l:%M%p') : '--:--:--'
  end

  def latlon_format(latitude, longitude)
    lat = formatted_latitude(latitude) || '[Unknown]'
    lon = formatted_longitude(longitude) || '[Unknown]'
    [lat, lon].join(' / ')
  end

  def formatted_latitude(latitude)
    latitude && (latitude.abs.to_s + (latitude >= 0 ? '°N' : '°S'))
  end

  def formatted_longitude(longitude)
    longitude && (longitude.abs.to_s + (longitude >= 0 ? '°E' : '°W'))
  end

  def elevation_format(elevation_in_meters)
    elevation_in_meters && (e(elevation_in_meters).to_s + ' ' + peu)
  end

  def distance_to_preferred(meters)
    number_with_delimiter(Split.distance_in_preferred_units(meters).round(1))
  end

  alias_method :d, :distance_to_preferred

  def elevation_to_preferred(meters)
    meters && number_with_delimiter(Split.elevation_in_preferred_units(meters).round(0))
  end

  alias_method :e, :elevation_to_preferred

  LENGTH_UNIT_MAP ||= {miles: {short: 'mi', singular: 'mile', plural: 'miles'},
                       kilometers: {short: 'km', singular: 'kilometer', plural: 'kilometers'},
                       meters: {short: 'm', singular: 'meter', plural: 'meters'},
                       feet: {short: 'ft', singular: 'foot', plural: 'feet'}}
                          .with_indifferent_access

  def preferred_distance_unit(param = 'plural')
    distance_unit = current_user.try(:pref_distance_unit) || 'miles'
    LENGTH_UNIT_MAP[distance_unit][param]
  end

  alias_method :pdu, :preferred_distance_unit

  def preferred_elevation_unit(param = 'plural')
    elevation_unit = current_user.try(:pref_elevation_unit) || 'feet'
    LENGTH_UNIT_MAP[elevation_unit][param]
  end

  alias_method :peu, :preferred_elevation_unit
end