class Location < ActiveRecord::Base
  include Auditable
  include UnitConversions
  has_many :splits

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates_numericality_of :elevation, greater_than_or_equal_to: -413, less_than_or_equal_to: 8848, allow_nil: true
  validates_numericality_of :latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true
  validates_numericality_of :longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true

  def elevation_as_entered
    Location.elevation_in_preferred_units(elevation, User.current).round(0) if elevation
  end

  def elevation_as_entered=(entered_elevation)
    self.elevation = Location.elevation_in_meters(entered_elevation.to_f, User.current) if entered_elevation.present?
  end

end
