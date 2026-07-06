class GatingLocationRow
  def initialize(effort:, gating_location_event:, crew_passage: nil)
    @effort = effort
    @gating_location_event = gating_location_event
    @crew_passage = crew_passage
  end

  attr_reader :crew_passage

  delegate :bib_number, :full_name, :stopped?, to: :effort
  delegate :id, to: :effort, prefix: true

  def crew_passed?
    crew_passage.present?
  end

  def event_short_name
    gating_location_event.event.guaranteed_short_name
  end

  # The runner's recorded time at the gating aid station's gate sub-split (its Out when the station
  # records one, otherwise its In), latest lap. Nil until that time exists: a runner who has only
  # checked In could still be at the aid station for a while, so anchoring the release projection on
  # the In time would release the crew too early.
  def gating_split_time
    return @gating_split_time if defined?(@gating_split_time)

    @gating_split_time = effort.split_times.select do |split_time|
      split_time.split_id == gating_split.id && split_time.bitkey == gating_bitkey
    end.max_by(&:lap)
  end

  def passed_gating?
    gating_split_time.present?
  end

  def gating_time_local
    gating_split_time&.absolute_time&.in_time_zone(home_time_zone)
  end

  # True once the runner has any recorded time at or beyond the target aid station,
  # at which point a release time is moot.
  def reached_target?
    furthest_target_split_time.present?
  end

  # True once the runner has progressed past the target aid station's In time — its Out time,
  # or any later aid station.
  def departed_target?
    split_time = furthest_target_split_time
    return false if split_time.nil?

    split_time.split_id != target_split.id || split_time.bitkey != SubSplit::IN_BITKEY
  end

  # The runner's most recent recorded time at or beyond the target aid station.
  def target_progress_time_local
    furthest_target_split_time&.absolute_time&.in_time_zone(home_time_zone)
  end

  # A label for the most recent split time at or beyond the target, e.g. "Departed Ouray"
  # or "Arrived Cunningham".
  def target_progress_label
    split_time = furthest_target_split_time
    return if split_time.nil?

    verb = split_time.bitkey == SubSplit::OUT_BITKEY ? "Departed" : "Arrived"
    "#{verb} #{split_time.split.base_name}"
  end

  # The runner's earliest predicted arrival at the target aid station, or nil when no release time
  # applies (not yet gated, stopped, already arrived, or no projection). The projection is anchored
  # on the runner's furthest recorded point between the gate and the target (see #projection_anchor),
  # so it refines as the runner progresses toward the target.
  def predicted_target_arrival
    return @predicted_target_arrival if defined?(@predicted_target_arrival)

    @predicted_target_arrival =
      if stopped? || reached_target? || !passed_gating?
        nil
      else
        anchor = projection_anchor
        anchor && (anchor.split_time.absolute_time + anchor.low_seconds.seconds)
      end
  end

  def predicted_target_arrival_local
    predicted_target_arrival&.in_time_zone(home_time_zone)
  end

  # The base name of the aid station the current projection is anchored on, e.g. "Cascade Creek Rd".
  def projection_anchor_label
    projection_anchor_split_time&.split&.base_name
  end

  def projection_anchor_time_local
    projection_anchor_split_time&.absolute_time&.in_time_zone(home_time_zone)
  end

  # True when the projection is anchored beyond the gating aid station — on an intermediate aid
  # station the runner has since reached — i.e. the estimate has been refined since leaving the gate.
  def anchored_beyond_gate?
    projection_anchor_split_time.present? && projection_anchor_split_time.split_id != gating_split.id
  end

  # Predicted target arrival minus the travel buffer, or nil when no release time applies.
  def release_time(buffer_minutes)
    arrival = predicted_target_arrival
    arrival && (arrival - buffer_minutes.minutes)
  end

  def release_time_local(buffer_minutes)
    release_time(buffer_minutes)&.in_time_zone(home_time_zone)
  end

  # True when the buffered release time is in the past, i.e. the crew can be released now.
  def released?(buffer_minutes)
    release = release_time(buffer_minutes)
    release.present? && release <= Time.current
  end

  # Ordering key for the "release time" sort: actionable runners (release now, then upcoming) first,
  # terminal states (stopped, arrived, departed) next, passed crews last; bib breaks ties.
  def release_sort_key(buffer_minutes)
    release = release_time(buffer_minutes)
    rank =
      if crew_passed? then 6
      elsif departed_target? then 5
      elsif reached_target? then 4
      elsif stopped? then 3
      elsif release.nil? then 2
      elsif release <= Time.current then 0
      else 1
      end
    secondary = rank == 1 ? release.to_i : 0
    [rank, secondary, bib_number.to_i]
  end

  ProjectionAnchor = Struct.new(:split_time, :low_seconds)

  private

  attr_reader :effort, :gating_location_event

  delegate :gating_split, :target_split, :gating_bitkey, to: :gating_location_event

  def projection_anchor_split_time
    projection_anchor&.split_time
  end

  def home_time_zone
    gating_location_event.event.home_time_zone
  end

  # The runner's most recent (furthest) recorded time at or beyond the target aid station.
  def furthest_target_split_time
    return @furthest_target_split_time if defined?(@furthest_target_split_time)

    target_distance = target_split.distance_from_start
    at_or_beyond = effort.split_times.select { |st| st.split.distance_from_start >= target_distance }
    @furthest_target_split_time = at_or_beyond.max_by { |st| [st.split.distance_from_start, st.bitkey] }
  end

  # The point the release projection is anchored on: the runner's furthest recorded time between the
  # gate (inclusive) and the target (exclusive) that yields a projection, walking back toward the gate
  # when a nearer point has no prior-year data. The gating aid station is only the *earliest* possible
  # anchor; a runner who has reached intermediate stations gets a more up-to-date estimate.
  def projection_anchor
    return @projection_anchor if defined?(@projection_anchor)

    ordered = anchor_candidates.sort_by { |st| [st.lap, st.split.distance_from_start, st.bitkey] }.reverse
    @projection_anchor = ordered.lazy.filter_map do |split_time|
      low_seconds = projected_low_seconds_from(split_time)
      ProjectionAnchor.new(split_time, low_seconds) if low_seconds
    end.first
  end

  # Recorded split times eligible to anchor the projection: those at or beyond the gate and before the
  # target. At the gating aid station only its gate sub-split counts (an In-only runner has not left
  # the gate); at intermediate stations any recorded time counts.
  def anchor_candidates
    gating_distance = gating_split.distance_from_start
    target_distance = target_split.distance_from_start

    effort.split_times.select do |split_time|
      distance = split_time.split.distance_from_start
      next false unless distance >= gating_distance && distance < target_distance
      next false if split_time.split_id == gating_split.id && split_time.bitkey != gating_bitkey

      true
    end
  end

  def projected_low_seconds_from(split_time)
    cache_key = ["gating_prediction", gating_location_event.id, split_time.id, split_time.updated_at]
    Rails.cache.fetch(cache_key) do
      Projection.execute_query(
        split_time: split_time,
        starting_time_point: gating_location_event.event.starting_time_point,
        subject_time_points: [TimePoint.new(split_time.lap, target_split.id, SubSplit::IN_BITKEY)],
      ).first&.low_seconds
    end
  end
end
