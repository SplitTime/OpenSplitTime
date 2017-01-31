class LiveEventFramework

  attr_reader :times_container
  delegate :multiple_laps?, to: :event

  def initialize(args)
    @event = args[:event]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    post_initialize(args)
  end

  def post_initialize(args)
    nil
  end

  def event_name
    event.name
  end

  def efforts_started_count
    efforts.count(&:started?)
  end

  def efforts_dropped_count
    efforts.count(&:dropped?)
  end

  def efforts_finished_count
    efforts.count(&:finished?)
  end

  def efforts_in_progress_count
    efforts.count(&:in_progress?)
  end

  def efforts
    @efforts ||= event.efforts.sorted_with_finish_status
  end

  def lap_splits
    @lap_splits ||= required_lap_splits.presence || event.lap_splits_through(highest_lap)
  end

  def indexed_lap_splits
    @indexed_lap_splits ||= lap_splits.index_by(&:key)
  end

  def time_points
    @time_points ||= lap_splits.map(&:time_points).flatten
  end

  private

  attr_reader :event
  delegate :required_lap_splits, :required_time_points, to: :event

  def highest_lap
    efforts.map(&:final_lap).compact.max
  end
end