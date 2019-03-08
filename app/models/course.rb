# frozen_string_literal: true

class Course < ApplicationRecord
  include Auditable
  include Delegable
  include SplitMethods
  include TimeZonable
  extend FriendlyId

  zonable_attribute :next_start_time
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization
  has_many :events, dependent: :restrict_with_error
  has_many :splits, dependent: :destroy
  has_one_attached :gpx
  delegate :stewards, to: :organization

  accepts_nested_attributes_for :splits, reject_if: lambda { |s| s[:distance_from_start].blank? && s[:distance_in_preferred_units].blank? }

  scope :used_for_organization, -> (organization) { organization.courses }
  scope :standard_includes, -> { includes(:splits) }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates :gpx,
            content_type: %w[application/gpx+xml text/xml application/xml application/octet-stream],
            size: {less_than: 500.kilobytes}

  def to_s
    slug
  end

  def earliest_event_date
    events.earliest&.start_time
  end

  def most_recent_event_date
    events.most_recent&.start_time
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

  def track_points
    return [] unless gpx.attached?
    return @track_points if defined?(@track_points)
    file = gpx.download
    gpx_file = GPX::GPXFile.new(gpx_data: file)
    points = gpx_file.tracks.flat_map(&:points)
    @track_points = points.map { |track_point| {lat: track_point.lat, lon: track_point.lon} }
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
end
