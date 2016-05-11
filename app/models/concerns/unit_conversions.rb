module UnitConversions
  extend ActiveSupport::Concern

  module ClassMethods

    def distance_in_meters(distance_in_pref, user)
      return distance_in_pref.miles.to.meters.value unless user
      case user.pref_distance_unit
        when 'miles'
          distance_in_pref.miles.to.meters.value
        when 'kilometers'
          distance_in_pref.kilometers.to.meters.value
        else
          distance_in_pref
      end
    end

    def elevation_in_meters(elevation_in_pref, user)
      return elevation_in_pref.feet.to.meters.value unless user
      case user.pref_elevation_unit
        when 'feet'
          elevation_in_pref.feet.to.meters.value
        when 'meters'
          elevation_in_pref
        else
          elevation_in_pref
      end
    end

    def distance_in_preferred_units(distance_in_meters, user)
      return distance_in_meters.meters.to.miles.value unless user
      case user.pref_distance_unit
        when 'miles'
          distance_in_meters.meters.to.miles.value
        when 'kilometers'
          distance_in_meters.meters.to.kilometers.value
        else
          distance_in_meters
      end
    end

    def elevation_in_preferred_units(elevation_in_meters, user)
      return elevation_in_meters.meters.to.feet.value unless user
      case user.pref_elevation_unit
        when 'feet'
          elevation_in_meters.meters.to.feet.value
        when 'meters'
          elevation_in_meters
        else
          elevation_in_meters
      end
    end

  end
end
