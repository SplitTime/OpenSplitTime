# frozen_string_literal: true

class Event < ApplicationRecord

  include Auditable
  include SplitMethods
  include LapsRequiredMethods
  extend FriendlyId
  friendly_id :name, use: :slugged
  strip_attributes collapse_spaces: true
  belongs_to :course
  belongs_to :event_group
  has_many :efforts, dependent: :destroy
  has_many :aid_stations, dependent: :destroy
  has_many :splits, through: :aid_stations
  has_many :live_times, dependent: :destroy
  has_many :partners, dependent: :destroy

  validates_presence_of :course_id, :name, :start_time, :laps_required, :home_time_zone, :event_group_id
  validates_uniqueness_of :name, case_sensitive: false
  validates_uniqueness_of :staging_id
  validate :home_time_zone_exists

  scope :name_search, -> (search_param) { where('name ILIKE ?', "%#{search_param}%") }
  scope :select_with_params, -> (search_param) do
    search(search_param)
        .select('events.*, COUNT(efforts.id) as effort_count')
        .left_joins(:efforts).left_joins(:event_group)
        .group('events.id, event_groups.id')
        .order(start_time: :desc)
  end
  scope :concealed, -> { includes(:event_group).where(event_groups: {concealed: true}) }
  scope :visible, -> { includes(:event_group).where(event_groups: {concealed: false}) }

  def self.search(search_param)
    return all if search_param.blank?
    name_search(search_param)
  end

  def self.latest
    order(start_time: :desc).first
  end

  def self.earliest
    order(:start_time).first
  end

  def self.most_recent
    where('start_time < ?', Time.now).order(start_time: :desc).first
  end

  def concealed
    event_group&.concealed
  end
  alias_method :concealed?, :concealed

  def available_live
    event_group&.available_live
  end
  alias_method :available_live?, :available_live

  def auto_live_times
    event_group&.auto_live_times
  end
  alias_method :auto_live_times?, :auto_live_times

  def organization
    event_group&.organization
  end

  def organization_id
    event_group&.organization_id
  end

  def events_within_group
    event_group&.events
  end

  def ordered_events_within_group
    event_group&.ordered_events
  end

  def home_time_zone_exists
    unless home_time_zone_valid?
      errors.add(:home_time_zone, "must be the name of an ActiveSupport::TimeZone object")
    end
  end

  def home_time_zone_valid?
    home_time_zone && ActiveSupport::TimeZone[home_time_zone].present?
  end

  def to_s
    slug
  end

  def start_time_in_home_zone
    return nil unless home_time_zone_valid?
    start_time&.in_time_zone(home_time_zone)
  end

  def start_time_in_home_zone=(time)
    raise ArgumentError, 'start_time_in_home_zone cannot be set without a valid home_time_zone' unless home_time_zone_valid?
    self.start_time = ActiveSupport::TimeZone[home_time_zone].parse(time)
  end

  def reconciled_efforts
    efforts.where.not(person_id: nil)
  end

  def unreconciled_efforts
    efforts.where(person_id: nil)
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

  def organization_name
    organization.try(:name)
  end

  def started?
    SplitTime.where(effort: efforts).present?
  end

  def set_dropped_attributes
    BulkEffortsStopper.stop(efforts: efforts)
  end

  def required_lap_splits
    @required_lap_splits ||= lap_splits_through(laps_required)
  end

  def required_time_points
    @required_time_points ||= time_points_through(laps_required)
  end

  def finished?
    efforts_ranked.present? && efforts_ranked.none?(&:in_progress?)
  end

  def efforts_ranked(args = {})
    efforts.ranked_with_finish_status(args)
  end

  def pick_partner_with_banner
    partners.with_banners.map { |partner| [partner] * partner.weight }.flatten.shuffle.first
  end

  def live_entry_attributes
    ordered_splits.map(&:live_entry_attributes)
  end

  def simple?
    (splits_count < 3) && !multiple_laps?
  end
end
