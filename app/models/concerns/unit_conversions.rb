# frozen_string_literal: true

module UnitConversions
  extend ActiveSupport::Concern

  METERS_PER_MILE = 1609.344
  METERS_PER_KM = 1000
  FEET_PER_METER = 3.28084

  module ClassMethods

    def entered_distance_to_meters(distance)
      preferred_distance_in_meters(distance.numericize)
    end

    def entered_elevation_to_meters(elevation)
      preferred_elevation_in_meters(elevation.numericize)
    end

    def meters_to_preferred_distance(meters)
      distance_in_preferred_units(meters.numericize)
    end

    def meters_to_preferred_elevation(meters)
      elevation_in_preferred_units(meters.numericize)
    end

    private

    def distance_in_preferred_units(distance_in_meters)
      case pref_distance_unit
      when 'miles'
        distance_in_meters / METERS_PER_MILE
      when 'kilometers'
        distance_in_meters / METERS_PER_KM
      else
        distance_in_meters
      end
    end


    def elevation_in_preferred_units(elevation_in_meters)
      return nil unless elevation_in_meters
      case pref_elevation_unit
      when 'feet'
        elevation_in_meters * FEET_PER_METER
      else
        elevation_in_meters
      end
    end

    def preferred_distance_in_meters(distance_in_pref)
      case pref_distance_unit
      when 'miles'
        (distance_in_pref * METERS_PER_MILE).round(0)
      when 'kilometers'
        (distance_in_pref * METERS_PER_KM).round(0)
      else
        distance_in_pref
      end
    end

    def preferred_elevation_in_meters(elevation_in_pref)
      return nil unless elevation_in_pref
      case pref_elevation_unit
      when 'feet'
        elevation_in_pref / FEET_PER_METER
      else
        elevation_in_pref
      end
    end

    def pref_distance_unit
      User.current&.pref_distance_unit || 'miles'
    end

    def pref_elevation_unit
      User.current&.pref_elevation_unit || 'feet'
    end
  end
end
