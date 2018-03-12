# frozen_string_literal: true

class LiveEventFramework
  attr_reader :event
  delegate :multiple_laps?, :home_time_zone, :ordered_events_within_group, to: :event

  def initialize(args)
    @event = args[:event]
    @times_container ||= args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    post_initialize(args)
  end

  def post_initialize(args)
    nil
  end

  def event_name
    event.name
  end

  def event_id
    event.id
  end

  def event_start_time
    event.start_time_in_home_zone
  end

  def efforts_started
    @efforts_started ||= event_efforts.select(&:started?)
  end

  def efforts_finished
    @efforts_finished ||= event_efforts.select(&:finished?)
  end

  def efforts_stopped
    @efforts_stopped ||= event_efforts.select(&:stopped?)
  end

  def efforts_dropped
    @efforts_dropped ||= event_efforts.select(&:dropped?)
  end
  
  def efforts_in_progress
    @efforts_in_progress ||= event_efforts.select(&:in_progress?)
  end
  
  def efforts_started_count
    efforts_started.size
  end

  def efforts_finished_count
    efforts_finished.size
  end

  def efforts_stopped_count
    efforts_stopped.size
  end

  def efforts_dropped_count
    efforts_dropped.size
  end

  def efforts_in_progress_count
    efforts_in_progress.size
  end

  def efforts_started_ids
    efforts_started.map(&:id)
  end

  def efforts_finished_ids
    efforts_finished.map(&:id)
  end

  def efforts_stopped_ids
    efforts_stopped.map(&:id)
  end

  def efforts_dropped_ids
    efforts_dropped.map(&:id)
  end

  def efforts_in_progress_ids
    efforts_in_progress.map(&:id)
  end

  def event_efforts
    @event_efforts ||= event.efforts.ranked_with_finish_status
  end

  def lap_splits
    @lap_splits ||= required_lap_splits.presence || event.lap_splits_through(highest_lap + 1)
  end

  def indexed_lap_splits
    @indexed_lap_splits ||= lap_splits.index_by(&:key)
  end

  def lap_split_keys
    @lap_split_keys ||= lap_splits.map(&:key)
  end

  def time_points
    @time_points ||= lap_splits.flat_map(&:time_points)
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def ordered_split_ids
    @ordered_split_ids ||= ordered_splits.map(&:id)
  end

  private

  delegate :required_lap_splits, :required_time_points, to: :event

  def highest_lap
    @highest_lap ||= event_efforts.map(&:final_lap).compact.max || 1
  end
end
