# frozen_string_literal: true

module UnitConversions
  extend ActiveSupport::Concern

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
        distance_in_meters.meters.to.miles.value
      when 'kilometers'
        distance_in_meters.meters.to.kilometers.value
      else
        distance_in_meters
      end
    end

    def elevation_in_preferred_units(elevation_in_meters)
      return nil unless elevation_in_meters
      case pref_elevation_unit
      when 'feet'
        elevation_in_meters.meters.to.feet.value
      else
        elevation_in_meters
      end
    end

    def preferred_distance_in_meters(distance_in_pref)
      case pref_distance_unit
      when 'miles'
        distance_in_pref.miles.to.meters.value.round(0)
      when 'kilometers'
        distance_in_pref.kilometers.to.meters.value.round(0)
      else
        distance_in_pref
      end
    end

    def preferred_elevation_in_meters(elevation_in_pref)
      return nil unless elevation_in_pref
      case pref_elevation_unit
      when 'feet'
        elevation_in_pref.feet.to.meters.value
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
