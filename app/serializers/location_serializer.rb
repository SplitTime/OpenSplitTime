class LocationSerializer < BaseSerializer
  attributes :id, :name, :latitude, :longitude, :elevation, :description
  link(:self) { api_v1_location_path(object) }
end