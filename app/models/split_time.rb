class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good]   # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :effort
  belongs_to :split

  validates_presence_of :effort_id, :split_id, :time_from_start
  validates :data_status, inclusion: { in: SplitTime.data_statuses.keys }, allow_nil: true
  validates_uniqueness_of :split_id, scope: :effort_id,
                          :message => "only one of any given split permitted within an effort"
  validates_numericality_of :time_from_start, equal_to: 0, :if => 'split_is_start?',
                            :message => "the starting split_time must have 0 time from start"
  validates_numericality_of :time_from_start, greater_than: 0, :unless => 'split_is_start?',
                            :message => "waypoint and finish split_times must have positive time from start"
  validate :course_is_consistent, unless: 'effort.nil? | split.nil?'   # TODO fix tests so that .nil? checks are not necessary

  def split_is_start?
    split_id.nil? ? false : split.kind == "start"
  end

  def course_is_consistent
    if effort.event.course_id != split.course_id
      errors.add(:effort_id, "the effort.event.course_id does not resolve with the split.course_id")
      errors.add(:split_id, "the effort.event.course_id does not resolve with the split.course_id")
    end
  end

end
