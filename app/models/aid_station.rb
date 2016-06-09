class AidStation < ActiveRecord::Base
  belongs_to :event
  belongs_to :split
  enum status: [:pre_open, :open, :closed, :released]


  validates_presence_of :event_id, :split_id

  attr_accessor :efforts_dropped_at_station, :efforts_in_aid, :efforts_recorded_out,
                :efforts_passed_without_record, :efforts_expected

  scope :ordered, -> { includes(:split).order('splits.distance_from_start') }

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

  def race_name
    race ? race.name : nil
  end

  def race
    event.race
  end

  def degrade_status
    current_status = AidStation.statuses[status]
    degraded_status = status ? [current_status - 1, 0].max : 0
    update(status: degraded_status)
  end

  def advance_status
    current_status = AidStation.statuses[status]
    advanced_status = status ? [current_status + 1, 3].min : 0
    update(status: advanced_status)
  end

end
