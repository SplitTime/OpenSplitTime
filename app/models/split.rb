class Split < ActiveRecord::Base
  include Auditable
  include UnitConversions
  enum kind: [:start, :finish, :waypoint]
  belongs_to :course
  belongs_to :location
  has_many :split_times, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :events, through: :event_splits

  accepts_nested_attributes_for :location, allow_destroy: true

  validates_presence_of :base_name, :distance_from_start, :sub_order, :kind
  validates :kind, inclusion: {in: Split.kinds.keys}
  validates_uniqueness_of :base_name, scope: [:course_id, :name_extension], case_sensitive: false,
                          message: "must be unique unless a name_extension is added to distinguish"
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

  scope :ordered, -> { order(:distance_from_start, :sub_order) }
  scope :at_same_distance, -> (split) { where(distance_from_start: split.distance_from_start).order(:sub_order) }
  scope :base, -> { where(sub_order: 0) }

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

  def name
    [base_name, name_extension].compact.join(' ')
  end

  def waypoint_group(event = nil)
    event ? event.waypoint_group(self) : course.waypoint_group(self)
  end

  def composite_name(event = nil)
    group = waypoint_group(event).pluck_to_hash(:base_name, :name_extension)
    "#{group[0][:base_name]} #{(group.map { |block| block[:name_extension] }.compact.join(' / '))}"
  end

  def earliest_event_date
    events.earliest.first_start_time
  end

  def latest_event_date
    events.most_recent.first_start_time
  end

  def random_location_name
    "#{name} Location #{(rand * 1000).to_i} (please change me)"
  end

end
