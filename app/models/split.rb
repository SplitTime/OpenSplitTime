class Split < ActiveRecord::Base
  include Auditable
  include StatisticalMethods
  include UnitConversions
  enum kind: [:start, :finish, :waypoint]
  belongs_to :course
  belongs_to :location
  has_many :split_times, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :events, through: :event_splits

  accepts_nested_attributes_for :location, allow_destroy: true

  validates_presence_of :name, :distance_from_start, :sub_order, :kind
  validates :kind, inclusion: {in: Split.kinds.keys}
  validates_uniqueness_of :name, scope: :course_id, case_sensitive: false
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_start?',
                          message: "only one start split permitted on a course"
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_finish?',
                          message: "only one finish split permitted on a course"
  validates_numericality_of :distance_from_start, equal_to: 0, if: 'is_start?',
                            message: "for the start split must be 0"
  validates_numericality_of :vert_gain_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: "for the start split must be 0"
  validates_numericality_of :vert_loss_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: "for the start split must be 0"
  validates_numericality_of :distance_from_start, greater_than: 0, :unless => 'is_start?',
                            message: "must be positive for waypoint and finish splits"
  validates_numericality_of :vert_gain_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: "may not be negative"
  validates_numericality_of :vert_loss_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: "may not be negative"

  def is_start?
    self.start?
  end

  def is_finish?
    self.finish?
  end

  def distance_as_entered
    Split.distance_in_preferred_units(distance_from_start, User.current).round(2) if distance_from_start
  end

  def distance_as_entered=(entered_distance)
    self.distance_from_start = Split.distance_in_meters(entered_distance.to_f, User.current) if entered_distance.present?
  end

  def vert_gain_as_entered
    Split.elevation_in_preferred_units(vert_gain_from_start, User.current).round(0) if vert_gain_from_start
  end

  def vert_gain_as_entered=(entered_vert_gain)
    self.vert_gain_from_start = Split.elevation_in_meters(entered_vert_gain.to_f, User.current) if entered_vert_gain.present?
  end

  def vert_loss_as_entered
    Split.elevation_in_preferred_units(vert_loss_from_start, User.current).round(0) if vert_loss_from_start
  end

  def vert_loss_as_entered=(entered_vert_loss)
    self.vert_loss_from_start = Split.elevation_in_meters(entered_vert_loss.to_f, User.current) if entered_vert_loss.present?
  end

  def self.ordered
    order(:distance_from_start, :sub_order)
  end

  def self.average_times(target_finish_time) # Returns a hash with split ids => average times from start
    efforts = first.course.relevant_efforts(target_finish_time)
    return_hash = {}
    all.each do |split|
      return_hash[split.id] = split.average_time(efforts)
    end
    return_hash
  end

  def time_hash
    Hash[SplitTime.where(split_id: id).pluck(:effort_id, :time_from_start)]
  end

  def average_time(relevant_efforts)
    split_times.where(effort_id: relevant_efforts.pluck(:id)).pluck(:time_from_start).mean
  end

  def waypoint_group
    course.splits.where(distance_from_start: distance_from_start).order(:sub_order)
  end

  def composite_name #TODO limit this to event_waypoint_group when that function is working
    (waypoint_group.order(:sub_order).map &:name).join(' / ')
  end

  def base_name
    name.split.reject { |x| (x.downcase == 'in') | (x.downcase == 'out') }.join(' ')
  end

  def earliest_event_date
    events.order(first_start_time: :asc).first.first_start_time
  end

  def latest_event_date
    events.order(first_start_time: :asc).last.first_start_time
  end

end
