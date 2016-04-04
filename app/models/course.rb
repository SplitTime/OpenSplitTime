class Course < ActiveRecord::Base
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, allow_destroy: true

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
end
