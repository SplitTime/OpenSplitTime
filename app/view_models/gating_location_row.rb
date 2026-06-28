class GatingLocationRow
  def initialize(effort:, gating_location_event:)
    @effort = effort
    @gating_location_event = gating_location_event
  end

  delegate :bib_number, :full_name, :stopped?, to: :effort

  def event_short_name
    gating_location_event.event.guaranteed_short_name
  end

  # The runner's recorded time at the gating aid station, latest lap, OUT preferred over IN.
  def gating_split_time
    return @gating_split_time if defined?(@gating_split_time)

    @gating_split_time = effort.split_times
                               .select { |split_time| split_time.split_id == gating_split.id }
                               .max_by { |split_time| [split_time.lap, split_time.bitkey] }
  end

  def passed_gating?
    gating_split_time.present?
  end

  def gating_time_in_zone(home_time_zone)
    gating_split_time&.absolute_time&.in_time_zone(home_time_zone)
  end

  # True once the runner has a recorded time at or beyond the target aid station,
  # at which point a release time is moot.
  def arrived_at_target?
    effort.split_times.any? { |split_time| split_time.split.distance_from_start >= target_split.distance_from_start }
  end

  # The runner's earliest predicted arrival at the target aid station, or nil when no
  # release time applies (not yet gated, stopped, already arrived, or no projection).
  def predicted_target_arrival
    return if stopped? || arrived_at_target? || !passed_gating?

    low_seconds = projected_low_seconds
    return if low_seconds.nil?

    gating_split_time.absolute_time + low_seconds.seconds
  end

  private

  attr_reader :effort, :gating_location_event

  delegate :gating_split, :target_split, to: :gating_location_event

  def projected_low_seconds
    cache_key = ["gating_prediction", gating_location_event.id, gating_split_time.id, gating_split_time.updated_at]
    Rails.cache.fetch(cache_key) do
      Projection.execute_query(
        split_time: gating_split_time,
        starting_time_point: gating_location_event.event.starting_time_point,
        subject_time_points: [TimePoint.new(gating_split_time.lap, target_split.id, SubSplit::IN_BITKEY)],
      ).first&.low_seconds
    end
  end
end
