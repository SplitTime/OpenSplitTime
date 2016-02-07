class Location < ActiveRecord::Base
  belongs_to :split

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :elevation, greater_than_or_equal_to: -413, less_than_or_equal_to: 8848, allow_nil: true
  validates_numericality_of :latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true
  validates_numericality_of :longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true
end
