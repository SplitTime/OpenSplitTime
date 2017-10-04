class Course < ApplicationRecord

  include Auditable
  include SplitMethods
  extend FriendlyId
  friendly_id :name, use: :slugged
  strip_attributes collapse_spaces: true
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, :reject_if => lambda { |s| s[:distance_from_start].blank? && s[:distance_in_preferred_units].blank? }

  scope :used_for_organization, -> (organization) { joins(:events).where(events: {organization_id: organization.id}).uniq }
  scope :standard_includes, -> { includes(:splits) }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

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
