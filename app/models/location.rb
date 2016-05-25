class Location < ActiveRecord::Base
  include Auditable
  include UnitConversions
  strip_attributes collapse_spaces: true
  has_many :splits

  before_destroy :disassociate_splits

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates_numericality_of :elevation, greater_than_or_equal_to: -413, less_than_or_equal_to: 8848, allow_nil: true
  validates_numericality_of :latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true
  validates_numericality_of :longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true

  scope :on_course, -> (course) { includes(:splits).where(splits: {course_id: course.id}) }

  def elevation_as_entered
    Location.elevation_in_preferred_units(elevation, User.current) if elevation
  end

  def elevation_as_entered=(entered_elevation)
    self.elevation = Location.elevation_in_meters(entered_elevation.to_f, User.current) if entered_elevation.present?
  end

  private

  def disassociate_splits
    Split.where(location: self).update_all(location_id: nil)
  end

end
