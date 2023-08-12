# frozen_string_literal: true

class Course < ApplicationRecord
  include UrlAccessible
  include TimeZonable
  include SplitMethods
  include Delegable
  include Concealable
  include Auditable
  extend FriendlyId

  zonable_attribute :next_start_time
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_paper_trail

  belongs_to :organization
  has_many :course_group_courses, dependent: :restrict_with_error
  has_many :course_groups, through: :course_group_courses, dependent: :restrict_with_error
  has_many :events, dependent: :restrict_with_error
  has_many :splits, dependent: :destroy
  has_one_attached :gpx

  accepts_nested_attributes_for :splits, reject_if: ->(s) { s[:distance_from_start].blank? && s[:distance_in_preferred_units].blank? }

  scope :standard_includes, -> { includes(:splits) }
  scope :with_policy_scope_attributes, -> { all }

  after_commit :sync_track_points, on: [:create, :update]

  validates_presence_of :name, :organization
  validates_uniqueness_of :name, case_sensitive: false
  validates :gpx,
            content_type: %w[application/gpx+xml text/xml application/xml application/octet-stream],
            size: {less_than: 500.kilobytes, message: "must be less than 0.5 MB"}

  def to_s
    slug
  end

  def add_basic_splits!
    splits << Split.new(base_name: "Start", kind: :start, sub_split_bitmap: 1, distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0)
    splits << Split.new(base_name: "Finish", kind: :finish, sub_split_bitmap: 1)
    self
  end

  # @return [Integer, nil]
  def average_finish_seconds
    starting_split_id = start_split.id
    finish_split_id = finish_split.id
    segments = EffortSegment.where(begin_split_id: starting_split_id, end_split_id: finish_split_id)
    return nil if segments.empty?

    segments.average(:elapsed_seconds).to_i
  end

  # @return [ActiveSupport::TimeWithZone, nil]
  def earliest_event_date
    events.earliest&.scheduled_start_time
  end

  # @return [ActiveSupport::TimeWithZone, nil]
  def most_recent_event_date
    events.most_recent&.scheduled_start_time
  end

  # @return [Event::ActiveRecord_AssociationRelation]
  def visible_events
    events.visible
  end

  # @return [String, nil]
  def home_time_zone
    events.latest&.home_time_zone
  end

  # @return [Integer, nil]
  def distance
    @distance ||= finish_split.distance_from_start if finish_split.present?
  end

  # @return [Integer, nil]
  def vert_gain
    @vert_gain ||= finish_split.vert_gain_from_start if finish_split.present?
  end

  # @return [Integer, nil]
  def vert_loss
    @vert_loss ||= finish_split.vert_loss_from_start if finish_split.present?
  end

  # @return [Boolean]
  def simple?
    splits_count < 3
  end

  private

  def sync_track_points
    return unless attachment_changes["gpx"].present?

    ::SyncTrackPointsJob.set(wait: 5.seconds).perform_later(id)
  end
end
