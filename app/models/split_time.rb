class SplitTime < ActiveRecord::Base
  include Auditable
  include StatisticalMethods
  enum data_status: [:bad, :questionable, :good, :confirmed] # nil = unknown, 0 = bad, 1 = questionable, 2 = good, 3 = confirmed
  belongs_to :effort
  belongs_to :split

  scope :valid_status, -> { where(data_status: [nil, 2, 3]) }

  after_update :set_effort_data_status, if: :time_from_start_changed?

  validates_presence_of :effort_id, :split_id, :time_from_start
  validates :data_status, inclusion: {in: SplitTime.data_statuses.keys}, allow_nil: true
  validates_uniqueness_of :split_id, scope: :effort_id,
                          :message => "only one of any given split permitted within an effort"
  validate :course_is_consistent, unless: 'effort.nil? | split.nil?' # TODO fix tests so that .nil? checks are not necessary

  def course_is_consistent
    if effort.event.course_id != split.course_id
      errors.add(:effort_id, "the effort.event.course_id does not resolve with the split.course_id")
      errors.add(:split_id, "the effort.event.course_id does not resolve with the split.course_id")
    end
  end

  def set_effort_data_status
    effort.set_data_status
  end

  def not_valid?
    (data_status == 'bad') | (data_status == 'questionable')
  end

  def time_as_entered
    return nil if time_from_start.nil?
    seconds = time_from_start % 60
    minutes = (time_from_start / 60) % 60
    hours = time_from_start / (60 * 60)
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  alias_method :formatted_time_hhmmss, :time_as_entered

  def time_as_entered=(entered_time)
    if entered_time.present?
      units = %w(hours minutes seconds)
      self.time_from_start = entered_time.split(':').map.with_index { |x, i| x.to_i.send(units[i]) }.reduce(:+).to_i
    else
      self.time_from_start = nil
    end
  end

  def segment_time
    return 0 if time_from_start == 0
    effort.segment_time(split)
  end

  def segment_distance
    effort.event.segment_distance(split)
  end

  def segment_velocity
    segment_time == 0 ? 0 : (segment_distance / segment_time)
  end

  def time_from_previous_valid
    previous = previous_valid_split_time
    previous ? time_from_start - previous.time_from_start : nil
  end

  def velocity_from_previous_valid
    previous = previous_valid_split_time
    previous ? effort.segment_velocity(Segment.new(previous.split, self.split)) : nil
  end

  def tfs_velocity
    time_from_start == 0 ? 0 : (split.distance_from_start / time_from_start)
  end

  def time_in_aid
    waypoint_group.compact.last.time_from_start - waypoint_group.compact.first.time_from_start
  end

  def previous_split_time
    effort.previous_split_time(self)
  end

  def previous_valid_split_time
    effort.previous_valid_split_time(self)
  end

  def self.ordered
    effort.ordered_split_times
  end

  def waypoint_group
    splits = split.waypoint_group
    split_time_array = []
    splits.each do |split|
      split_time_array << split.split_times.where(effort: effort).first
    end
    split_time_array # Includes nil values when no split_time is associated with members of the split.waypoint_group
  end

  def in_waypoint_group_with(other_split_time)
    split.distance_from_start == other_split_time.split.distance_from_start
  end

  def not_in_waypoint_group_with(other_split_time)
    split.distance_from_start != other_split_time.split.distance_from_start
  end

  def self.confirmed!
    all.each { |split_time| split_time.confirmed! }
  end

  def self.good!
    all.each { |split_time| split_time.good! }
  end

end
