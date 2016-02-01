class Event < ActiveRecord::Base
  validates_presence_of :course_id, :name, :start_date
  validates_uniqueness_of :name
  belongs_to :course
  belongs_to :race
end
