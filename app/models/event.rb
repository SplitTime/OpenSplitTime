class Event < ActiveRecord::Base
  belongs_to :course
  belongs_to :race
  has_many :efforts
  has_many :event_splits
  has_many :splits, through: :event_splits

  validates_presence_of :course_id, :name, :start_date
  validates_uniqueness_of :name, case_sensitive: false
end
