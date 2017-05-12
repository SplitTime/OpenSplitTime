class AidStation < ActiveRecord::Base
  belongs_to :event
  belongs_to :split
  enum status: [:pre_open, :open, :closed, :released]

  validates_uniqueness_of :split_id, scope: :event_id,
                          message: 'only one of any given split permitted within an event'
  validates_presence_of :event_id, :split_id
  validate :course_is_consistent

  attr_accessor :efforts_dropped_at_station, :efforts_in_aid, :efforts_recorded_out,
                :efforts_passed_without_record, :efforts_expected

  scope :ordered, -> { includes(:split).order('splits.distance_from_start') }

  def course_is_consistent
    if event && split && event.course_id != split.course_id
      errors.add(:event_id, "event's course is not the same as split's course")
      errors.add(:split_id, "event's course is not the same as split's course")
    end
  end

  def split_name
    split.base_name
  end

  def event_name
    event.name
  end

  def course_name
    course.name
  end

  def course
    split.course
  end

  def organization_name
    organization.try(:name)
  end

  def organization
    event.organization
  end
end
