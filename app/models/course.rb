class Course < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :splits
  has_many :events
  accepts_nested_attributes_for :splits, allow_destroy: true
end
