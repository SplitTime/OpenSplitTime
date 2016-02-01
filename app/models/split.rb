class Split < ActiveRecord::Base
  enum type: [:start, :finish, :waypoint]
  validates_presence_of :course_id, :location_id, :name, :distance_from_start, :type
  validates_uniqueness_of :name, scope: :course_id
  validates_uniqueness_of :distance_from_start, scope: [:course_id, :order_among_splits_of_same_distance]
  validates_uniqueness_of :type, scope: :course_id, :if => :type == :start, :message => 'only one start split permitted on a course'
  validates_uniqueness_of :type, scope: :course_id, :if => :type == :finish, :message => 'only one finish split permitted on a course'
  belongs_to :course
  belongs_to :location
end
