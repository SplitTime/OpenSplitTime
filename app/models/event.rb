class Event < ActiveRecord::Base
  belongs_to :course
  belongs_to :race

  validates_presence_of :course_id, :name, :start_date
  validates_uniqueness_of :name
end
