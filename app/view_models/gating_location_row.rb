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

  # The gate's time — its Out when the station records one, else In, latest lap. Nil until recorded, so
  # an In-only runner (possibly lingering at the aid station) doesn't release the crew early.
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

  # True once the runner has a recorded time at or beyond the target, making a release moot.
  def reached_target?
    furthest_target_split_time.present?
  end

  # True once the runner is past the target's In — its Out, or any later station.
  def departed_target?
    split_time = furthest_target_split_time
    return false if split_time.nil?

    split_time.split_id != target_split.id || split_time.bitkey != SubSplit::IN_BITKEY
  end

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

  # Earliest predicted arrival at the target, or nil (not gated, stopped, arrived, or no projection).
  # Anchored on the runner's furthest recorded point between gate and target (see #projection_anchor).
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

  # True when the projection is anchored on an intermediate station — the estimate has refined past the gate.
  def anchored_beyond_gate?
    projection_anchor_split_time.present? && projection_anchor_split_time.split_id != gating_split.id
  end

  # Whether the shown release can still change as the runner reaches interim stations — to warn crews.
  def release_may_update?
    update_release_times && interim_splits.present?
  end

  def interim_split_names
    interim_splits.map(&:base_name)
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

  delegate :gating_split, :target_split, :gating_bitkey, :update_release_times, :interim_splits,
           to: :gating_location_event

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

  # The projection's anchor: the runner's furthest recorded point between gate (inclusive) and target
  # (exclusive) that yields a projection, walking back toward the gate when a nearer point has no data.
  def projection_anchor
    return @projection_anchor if defined?(@projection_anchor)

    ordered = anchor_candidates.sort_by { |st| [st.lap, st.split.distance_from_start, st.bitkey] }.reverse
    @projection_anchor = ordered.lazy.filter_map do |split_time|
      low_seconds = projected_low_seconds_from(split_time)
      ProjectionAnchor.new(split_time, low_seconds) if low_seconds
    end.first
  end

  # Split times eligible to anchor the projection, gate (inclusive) to target (exclusive), counting only
  # the gate's sub-split at the gate. A non-updating gate uses just the gate, holding its release
  # constant (interim progress ignored; a drop still nullifies via the stopped? guard).
  def anchor_candidates
    return [gating_split_time].compact unless update_release_times

    gating_distance = gating_split.distance_from_start
    target_distance = target_split.distance_from_start

    effort.split_times.select do |split_time|
      distance = split_time.split.distance_from_start
      next false unless distance >= gating_distance && distance < target_distance
      next false if split_time.split_id == gating_split.id && split_time.bitkey != gating_bitkey

      true
    end
  end

  # Cache key busts on an anchor time correction (id + updated_at) or a re-pointed target.
  def projected_low_seconds_from(split_time)
    cache_key = ["gating_prediction", gating_location_event.id, target_split.id, split_time.id, split_time.updated_at]
    Rails.cache.fetch(cache_key) do
      Projection.execute_query(
        split_time: split_time,
        starting_time_point: gating_location_event.event.starting_time_point,
        subject_time_points: [TimePoint.new(split_time.lap, target_split.id, SubSplit::IN_BITKEY)],
      ).first&.low_seconds
    end
  end
end
