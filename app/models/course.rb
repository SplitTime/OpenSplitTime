class Course < ActiveRecord::Base
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, allow_destroy: true

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def earliest_event_date
    events.order(:first_start_time).first.first_start_time
  end

  def latest_event_date
    events.order(:first_start_time).last.first_start_time
  end

  def sorted_efforts
    effort_ids = sorted_effort_ids
    efforts_by_id = Effort.find(effort_ids).index_by(&:id)
    effort_ids.collect {|id| efforts_by_id[id] }
  end


  def sorted_effort_ids
    course_effort_ids = Effort.includes(:event).where(events: {course_id: id}).map(&:id)
    course_split_times = SplitTime.includes(:split, :effort).where(efforts: {id: course_effort_ids}, splits: {kind: 1}).order(:time_from_start)
    course_split_times.map(&:effort_id)
  end

end
