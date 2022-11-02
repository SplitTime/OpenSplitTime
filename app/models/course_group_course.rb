class CourseGroupCourse < ApplicationRecord
  belongs_to :course_group
  belongs_to :course

  validates_presence_of :course_group, :course
end
