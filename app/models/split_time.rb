class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :effort
  belongs_to :split

  validates_presence_of :effort_id, :split_id, :time_from_start
  validates :data_status, inclusion: {in: SplitTime.data_statuses.keys}, allow_nil: true
  validates_uniqueness_of :split_id, scope: :effort_id,
                          :message => "only one of any given split permitted within an effort"
  validate :course_is_consistent, unless: 'effort.nil? | split.nil?' # TODO fix tests so that .nil? checks are not necessary

  def split_is_start?
    split.try(:kind) == "start"
  end

  def course_is_consistent
    if effort.event.course_id != split.course_id
      errors.add(:effort_id, "the effort.event.course_id does not resolve with the split.course_id")
      errors.add(:split_id, "the effort.event.course_id does not resolve with the split.course_id")
    end
  end

  def formatted_time
    seconds = time_from_start % 60
    minutes = (time_from_start / 60) % 60
    hours = time_from_start / (60 * 60)

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def segment_time
    ordered_group = effort.ordered_split_times
    position = ordered_group.map(&:id).index(id)
    position == 0 ? 0 : ordered_group[position].time_from_start - ordered_group[position - 1].time_from_start
  end

  def time_in_aid
    waypoint_group.compact.last.time_from_start - waypoint_group.compact.first.time_from_start
  end

  def waypoint_group
    splits = split.waypoint_group
    split_time_array = []
    splits.each do |split|
      split_time_array << split.split_times.where(effort: effort).first
    end
    split_time_array # Includes nil values when no split_time is associated with members of the split.waypoint_group
  end

end
