class CrewPassage < ApplicationRecord
  belongs_to :gating_location
  belongs_to :effort

  validates :passed_at, presence: true
  validates :effort_id, uniqueness: { scope: :gating_location_id,
                                      message: "only one crew passage permitted per gating location" }
  validate :effort_event_is_gated_at_location

  # Other stewards' open boards learn of passage marks by refresh; the marking
  # steward's own board already updated via the toggle's turbo_stream response.
  # A single registration is deliberate: separate after_create_commit and
  # after_destroy_commit calls naming the same method would deduplicate, leaving
  # only the last one active.
  after_commit :broadcast_crew_access_refresh, on: [:create, :destroy]

  delegate :event_group, to: :gating_location

  private

  def broadcast_crew_access_refresh
    # In a cascading destroy (event group teardown), the gating location or its
    # event group may already be gone by the time this commit callback fires
    target_event_group = gating_location&.event_group
    return if target_event_group.blank?

    broadcast_refresh_later_to(target_event_group, :crew_access)
  end

  def effort_event_is_gated_at_location
    return if effort.blank? || gating_location.blank?

    return if gating_location.gating_location_events.exists?(event_id: effort.event_id)

    errors.add(:effort_id, "must belong to an event gated at this location")
  end
end
