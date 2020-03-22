# frozen_string_literal: true

class Event < ApplicationRecord
  include Auditable, Delegable, SplitMethods, LapsRequiredMethods, Reconcilable, TimeZonable
  extend FriendlyId

  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  zonable_attributes :start_time
  has_paper_trail

  belongs_to :course
  belongs_to :event_group
  belongs_to :results_template
  has_many :event_series_events, dependent: :destroy
  has_many :event_series, through: :event_series_events
  has_many :efforts, dependent: :destroy
  has_many :aid_stations, dependent: :destroy
  has_many :splits, through: :aid_stations
  has_many :partners, through: :event_group

  delegate :concealed, :concealed?, :visible?, :available_live, :available_live?,
           :organization, :permit_notifications?, :home_time_zone, to: :event_group

  validates_presence_of :course_id, :start_time, :laps_required, :event_group, :results_template
  validates_uniqueness_of :short_name, case_sensitive: false, scope: :event_group_id
  validate :course_is_consistent

  before_validation :add_default_results_template
  before_validation :conform_changed_course
  before_save :add_all_course_splits
  after_save :validate_event_group
  after_destroy :destroy_orphaned_event_group

  scope :name_search, -> (search_param) { where('events.name ILIKE ?', "%#{search_param}%") }
  scope :select_with_params, -> (search_param) do
    search(search_param)
        .left_joins(:efforts).left_joins(:event_group)
        .group('events.id, event_groups.id')
  end
  scope :concealed, -> { includes(:event_group).where(event_groups: {concealed: true}) }
  scope :visible, -> { includes(:event_group).where(event_groups: {concealed: false}) }
  scope :standard_includes, -> { includes(:splits, :efforts, :event_group) }
  scope :with_policy_scope_attributes, -> do
    from(select('events.*, event_groups.organization_id, event_groups.concealed').joins(:event_group), :events)
  end

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

  def events_within_group
    event_group&.events
  end

  def ordered_events_within_group
    event_group&.ordered_events
  end

  def name
    event_group_name = event_group&.name || 'Nonexistent Event Group'
    short_name ? "#{event_group_name} (#{short_name})" : event_group_name
  end

  def guaranteed_short_name
    short_name || name
  end

  def course_is_consistent
    if splits.any? { |split| split.course_id != course_id }
      errors.add(:course_id, "does not reconcile with one or more splits")
    end
  end

  def to_s
    slug
  end

  def split_times
    SplitTime.joins(:effort).where(efforts: {event_id: id})
  end

  def split_times_data
    @split_times_data ||= SplitTimeQuery.time_detail(scope: {efforts: {event_id: id}}, home_time_zone: home_time_zone)
  end

  def course_name
    course.name
  end

  def organization_id
    attributes.key?('organization_id') ? attributes['organization_id'] : organization&.id
  end

  def organization_name
    organization&.name
  end

  def started?
    SplitTime.joins(:effort).where(efforts: {event_id: id}).limit(1).present?
  end

  def required_lap_splits
    @required_lap_splits ||= lap_splits_through(laps_required)
  end

  def required_time_points
    @required_time_points ||= time_points_through(laps_required)
  end

  def finished?
    ranked_efforts.present? && ranked_efforts.any?(&:started?) && ranked_efforts.none?(&:in_progress?)
  end

  def ranked_efforts(args = {})
    @ranked_efforts ||= Hash.new do |h, key|
      h[key] = efforts.ranked_with_status(args)
    end
    @ranked_efforts[args]
  end

  def simple?
    (splits_count < 3) && !multiple_laps?
  end

  def multiple_sub_splits?
    splits.any? { |split| split.sub_split_bitmap != 1 }
  end

  def ordered_aid_stations
    @ordered_aid_stations ||= aid_stations.sort_by(&:distance_from_start)
  end

  def should_generate_new_friendly_id?
    slug.blank? || short_name_changed? || event_group&.name_changed?
  end

  private

  def add_default_results_template
    self.results_template ||= ResultsTemplate.default
  end

  def conform_changed_course
    if persisted? && course_id_changed?
      response = Interactors::ChangeEventCourse.perform!(event: self, new_course: course)
      response.errors.each { |error| errors.add(:base, error[:title]) }
      response.successful?
    end
  end

  def destroy_orphaned_event_group
    event_group.reload

    if events_within_group.empty?
      event_group.destroy
    end
  end

  def add_all_course_splits
    if splits.empty?
      splits << course.splits
    end
  end

  def validate_event_group
    event_group = EventGroup.where(id: event_group_id).includes(events: :splits).first

    unless event_group.valid?
      errors.merge!(event_group.errors)
      raise ActiveRecord::RecordInvalid.new(self) # Causes a transaction to rollback
    end
  end
end
