class CrewPassage < ApplicationRecord
  belongs_to :gating_location
  belongs_to :effort

  validates :passed_at, presence: true
  validates :effort_id, uniqueness: { scope: :gating_location_id,
                                      message: "only one crew passage permitted per gating location" }
  validate :effort_event_is_gated_at_location

  delegate :event_group, to: :gating_location

  private

  def effort_event_is_gated_at_location
    return if effort.blank? || gating_location.blank?

    return if gating_location.gating_location_events.exists?(event_id: effort.event_id)

    errors.add(:effort_id, "must belong to an event gated at this location")
  end
end
