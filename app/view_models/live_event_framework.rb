class LiveEventFramework

  EFFORT_CATEGORIES = [:started, :dropped, :finished, :in_progress]

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

  def event_start_time
    event.start_time
  end

  EFFORT_CATEGORIES.each do |category|
    define_method("efforts_#{category}") do
      efforts.select { |effort| effort.send("#{category}?") }
    end
  end

  EFFORT_CATEGORIES.each do |category|
    define_method("efforts_#{category}_count") do
      efforts.count { |effort| effort.send("#{category}?") }
    end
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