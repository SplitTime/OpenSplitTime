class AidStation < ActiveRecord::Base
  belongs_to :event
  belongs_to :split
  enum status: [:pre_open, :open, :closed, :released]


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

  def race_name
    race && race.name
  end

  def race
    event.race
  end

  def degrade_status
    current_status_int = AidStation.statuses[status]
    degraded_status_int = status ? [current_status_int - 1, 0].max : 0
    degraded_status = AidStation.statuses.key(degraded_status_int)
    report = {}

    if status == 'pre_open'
      report[:status] = :warning
      report[:text] = "#{split_name} is already in #{status.titleize} status."
      return report
    end

    if update(status: degraded_status_int)
      report[:status] = :success
      report[:text] = "#{split_name} was changed to #{degraded_status.titleize} status."
    else
      report[:status] = :warning
      report[:text] = "Could not change #{split_name} to #{degraded_status.titleize} status."
    end
    report
  end

  def advance_status
    current_status_int = AidStation.statuses[status]
    advanced_status_int = status ? [current_status_int + 1, 3].min : 0
    advanced_status = AidStation.statuses.key(advanced_status_int)
    aid_station_report = AidStationsDisplay.new(event)
    expected = aid_station_report.efforts_expected_count(self)
    expected_next = aid_station_report.efforts_expected_count_next(self)
    next_name = aid_station_report.split_name_next(self)
    report = {}

    case status
    when 'open'
      if expected > 0
        report[:status] = :warning
        report[:text] = "Cannot change #{split_name} status to #{advanced_status.titleize} because #{expected} people are still expected there."
        return report
      end
    when 'closed'
      if expected_next > 0
        report[:status] = :warning
        report[:text] = "Cannot change #{split_name} status to #{advanced_status.titleize} because #{next_name} is still expecting #{expected_next} #{expected_next == 1 ? 'person' : 'people'}."
        return report
      end
    when 'released'
      report[:status] = :warning
      report[:text] = "#{split_name} is already in #{status.titleize} status."
      return report
    end

    if update(status: advanced_status_int)
      report[:status] = :success
      report[:text] = "#{split_name} was changed to #{advanced_status.titleize} status."
    else
      report[:status] = :warning
      report[:text] = "Could not change #{split_name} to #{advanced_status.titleize} status."
    end
    report
  end

end
