# frozen_string_literal: true

module MeasurementFormats
  extend ActiveSupport::Concern

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
    number_with_delimiter(Split.meters_to_preferred_distance(meters).round(1))
  end
  alias_method :d, :distance_to_preferred

  def elevation_to_preferred(meters)
    meters && number_with_delimiter(Split.meters_to_preferred_elevation(meters).round(0))
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