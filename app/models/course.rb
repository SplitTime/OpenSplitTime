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
    splits << Split.new(base_name: "Start", kind: :start, sub_split_bitmap: 1, distance_from_start: 0)
    splits << Split.new(base_name: "Finish", kind: :finish, sub_split_bitmap: 1)
    self
  end

  def earliest_event_date
    events.earliest&.scheduled_start_time
  end

  def most_recent_event_date
    events.most_recent&.scheduled_start_time
  end

  def visible_events
    events.visible
  end

  def home_time_zone
    events.latest&.home_time_zone
  end

  def distance
    @distance ||= finish_split.distance_from_start if finish_split.present?
  end

  def vert_gain
    @vert_gain ||= finish_split.vert_gain_from_start if finish_split.present?
  end

  def vert_loss
    @vert_loss ||= finish_split.vert_loss_from_start if finish_split.present?
  end

  def simple?
    splits_count < 3
  end

  private

  def sync_track_points
    return unless attachment_changes["gpx"].present?

    ::SyncTrackPointsJob.perform_later(self)
  end
end
