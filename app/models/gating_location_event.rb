class GatingLocationEvent < ApplicationRecord
  belongs_to :gating_location
  belongs_to :event
  belongs_to :gating_aid_station, class_name: "AidStation"
  belongs_to :target_aid_station, class_name: "AidStation"

  validates :event_id, uniqueness: { scope: :gating_location_id,
                                     message: "only one configuration permitted per event within a gating location" }
  validates :default_travel_buffer,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1200 }
  validate :aid_stations_belong_to_event
  validate :event_belongs_to_event_group
  validate :gating_precedes_target

  delegate :event_group, to: :gating_location

  def gating_split
    gating_aid_station&.split
  end

  def target_split
    target_aid_station&.split
  end

  # "In" or "Out" — the gating aid station's departure sub-split (Out when it records one),
  # i.e. the point at which a runner is considered past the gate.
  def gating_sub_split_kind
    SubSplit.kind(gating_split.sub_split_bitkeys.max) if gating_split
  end

  private

  def aid_stations_belong_to_event
    return if event.blank?

    if gating_aid_station.present? && gating_aid_station.event_id != event.id
      errors.add(:gating_aid_station_id, "must be an aid station of the same event")
    end

    return unless target_aid_station.present? && target_aid_station.event_id != event.id

    errors.add(:target_aid_station_id, "must be an aid station of the same event")
  end

  def event_belongs_to_event_group
    return if event.blank? || gating_location.blank?

    return unless event.event_group_id != gating_location.event_group_id

    errors.add(:event_id, "must belong to the same event group as the gating location")
  end

  def gating_precedes_target
    return if gating_split.blank? || target_split.blank?
    return if errors.include?(:gating_aid_station_id) || errors.include?(:target_aid_station_id)

    return unless gating_split.distance_from_start >= target_split.distance_from_start

    errors.add(:target_aid_station_id, "must be farther along the course than the gating aid station")
  end
end
