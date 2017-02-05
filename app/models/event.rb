class Event < ActiveRecord::Base
  include Auditable
  include Concealable
  include SplitMethods
  strip_attributes collapse_spaces: true
  belongs_to :course
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :aid_stations, dependent: :destroy
  has_many :splits, through: :aid_stations

  validates_presence_of :course_id, :name, :start_time, :laps_required
  validates_uniqueness_of :name, case_sensitive: false

  scope :recent, -> (max) { where('start_time < ?', Time.now).order(start_time: :desc).limit(max) }
  scope :most_recent, -> { where('start_time < ?', Time.now).order(start_time: :desc).first }
  scope :latest, -> { order(start_time: :desc).first }
  scope :earliest, -> { order(:start_time).first }
  scope :name_search, -> (search_param) { where('name ILIKE ?', "%#{search_param}%") }
  scope :select_with_params, -> (search_param) { search(search_param)
                                                     .where(concealed: false)
                                                     .select("events.*, COUNT(efforts.id) as effort_count")
                                                     .joins("LEFT OUTER JOIN efforts ON (efforts.event_id = events.id)")
                                                     .group("events.id").order(start_time: :desc) }

  def self.search(search_param)
    return all if search_param.blank?
    name_search(search_param)
  end

  delegate :cycled_lap_splits, :cycled_time_points, :lap_splits_through, :time_points_through, to: :course

  def reconciled_efforts
    efforts.where.not(participant_id: nil)
  end

  def unreconciled_efforts
    efforts.where(participant_id: nil)
  end

  def unreconciled_efforts?
    unreconciled_efforts.present?
  end

  def set_all_course_splits
    splits << course.splits
  end

  def split_times
    SplitTime.includes(:effort).where(efforts: {event_id: id})
  end

  def course_name
    course.name
  end

  def race_name
    race.try(:name)
  end

  def started?
    SplitTime.where(effort: efforts).present?
  end

  def set_dropped_attributes
    DroppedAttributesSetter.set_attributes(efforts: efforts)
  end

  def required_lap_splits
    @required_lap_splits ||= lap_splits_through(laps_required)
  end

  def required_time_points
    @required_time_points ||= time_points_through(laps_required)
  end

  def laps_unlimited?
    laps_required.zero?
  end

  def multiple_laps?
    laps_required != 1
  end

  def maximum_laps
    required_laps unless laps_unlimited?
  end

  def finished?
    efforts_sorted.none?(&:in_progress?)
  end

  private

  def efforts_sorted
    @efforts_sorted ||= efforts.sorted_with_finish_status
  end
end