# frozen_string_literal: true

class Course < ApplicationRecord

  include Auditable
  include SplitMethods
  extend FriendlyId
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, :reject_if => lambda { |s| s[:distance_from_start].blank? && s[:distance_in_preferred_units].blank? }
  has_attached_file :gpx
  include DeletableAttachment

  scope :used_for_organization, -> (organization) { includes(events: :event_group).where(event_groups: {organization_id: organization.id}).uniq }
  scope :standard_includes, -> { includes(:splits) }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates_attachment :gpx,
                       content_type: {content_type: %w[application/gpx+xml text/xml application/xml application/octet-stream]},
                       file_name: {matches: /gpx\Z/},
                       size: {in: 0..500.kilobytes}

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

  def distance
    @distance ||= ordered_splits.last.distance_from_start if ordered_splits.present?
  end

  def track_points
    return [] unless gpx.present?
    return @track_points if defined?(@track_points)
    file = Paperclip.io_adapters.for(gpx).read
    gpx_file = GPX::GPXFile.new(gpx_data: file)
    points = gpx_file.tracks.flat_map(&:points)
    @track_points = points.map { |track_point| {lat: track_point.lat, lon: track_point.lon} }
  end

  def vert_gain
    @vert_gain ||= ordered_splits.last.vert_gain_from_start if ordered_splits.present?
  end

  def vert_loss
    @vert_loss ||= ordered_splits.last.vert_loss_from_start if ordered_splits.present?
  end

  def simple?
    splits_count < 3
  end
end
