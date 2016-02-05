class Split < ActiveRecord::Base
  enum kind: [:start, :finish, :waypoint]
  validates_presence_of :course_id, :location_id, :name, :distance_from_start, :sub_order, :kind
  validates_uniqueness_of :name, scope: :course_id
  validates_uniqueness_of :distance_from_start, scope: [:course_id, :sub_order]
  validates_uniqueness_of :kind, scope: :course_id, conditions: -> { where(kind: 0) }, :message => "only one start split permitted on a course"
  validates_uniqueness_of :kind, scope: :course_id, conditions: -> { where(kind: 1) }, :message => "only one finish split permitted on a course"
  belongs_to :course
  belongs_to :location

end
