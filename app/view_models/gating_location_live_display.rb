class GatingLocationLiveDisplay
  def initialize(gating_location:, adjusted_event_id: nil, adjusted_buffer: nil)
    @gating_location = gating_location
    @adjusted_event_id = adjusted_event_id.to_i
    @adjusted_buffer = adjusted_buffer.presence&.to_i&.clamp(0, 1200)
  end

  attr_reader :gating_location

  delegate :name, :event_group, to: :gating_location

  def gated_events
    @gated_events ||= gating_location.gating_location_events
                                     .sort_by { |gle| gle.event.guaranteed_short_name }
  end

  # The buffer in effect for one gated event: the steward's adjusted value when they just
  # changed this event's control, otherwise the event's saved default.
  def buffer_for(gating_location_event)
    if adjusted_buffer && gating_location_event.id == adjusted_event_id
      adjusted_buffer
    else
      gating_location_event.default_travel_buffer
    end
  end

  # Rows for one gated event: runners who have passed the gating aid station, ordered by
  # bib. Stopped and already-arrived runners are included (with no release time).
  def rows_for(gating_location_event)
    passed_efforts(gating_location_event)
      .map { |effort| GatingLocationRow.new(effort: effort, gating_location_event: gating_location_event) }
      .sort_by { |row| row.bib_number.to_i }
  end

  private

  attr_reader :adjusted_event_id, :adjusted_buffer

  def passed_efforts(gating_location_event)
    effort_ids = SplitTime.where(split_id: gating_location_event.gating_split.id,
                                 effort_id: gating_location_event.event.efforts.select(:id))
                          .distinct.pluck(:effort_id)
    Effort.where(id: effort_ids).includes(split_times: :split)
  end
end
