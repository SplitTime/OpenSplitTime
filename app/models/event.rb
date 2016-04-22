class Event < ActiveRecord::Base
  include Auditable
  include SplitMethods
  belongs_to :course, touch: true
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :splits, through: :event_splits

  validates_presence_of :course_id, :name, :first_start_time
  validates_uniqueness_of :name, case_sensitive: false

  def all_splits_on_course?
    splits.each do |split|
      return false if split.course_id != course_id
    end
    true
  end

  def unreconciled_efforts
    efforts.where(participant_id: nil)
  end

  def unreconciled_efforts?
    efforts.where(participant_id: nil).count > 0
  end

  def set_all_course_splits
    splits << course.splits
  end

end
