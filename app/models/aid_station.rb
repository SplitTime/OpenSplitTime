class AidStation < ApplicationRecord
  include UrlAccessible

  belongs_to :event, touch: true
  belongs_to :split
  has_many :gating_location_events_as_gating, class_name: "GatingLocationEvent", foreign_key: :gating_aid_station_id,
                                              dependent: :destroy, inverse_of: :gating_aid_station
  has_many :gating_location_events_as_target, class_name: "GatingLocationEvent", foreign_key: :target_aid_station_id,
                                              dependent: :destroy, inverse_of: :target_aid_station

  validates :split_id, uniqueness: { scope: :event_id, message: "only one of any given split permitted within an event" } # rubocop:disable Rails/UniqueValidationWithoutIndex, Layout/LineLength
  validates_with AidStationAttributesValidator

  attr_accessor :efforts_dropped_at_station, :efforts_in_aid, :efforts_recorded_out,
                :efforts_passed_without_record, :efforts_expected

  delegate :course, :distance_from_start, to: :split
  delegate :event_group, to: :event
  delegate :organization, to: :event_group

  scope :ordered, -> { includes(:split).order("splits.distance_from_start") }

  def to_s
    "#{event.slug} at #{split.slug}"
  end

  def course_name
    course.name
  end

  def event_name
    event.name
  end

  def organization_name
    organization.name
  end

  def split_name
    split.base_name
  end
end
