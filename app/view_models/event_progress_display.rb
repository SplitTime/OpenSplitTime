class EventProgressDisplay

  attr_reader :event, :live_event, :past_due_threshold
  delegate :live_efforts, :efforts_started_count, :efforts_finished_count, :efforts_dropped_count,
           :efforts_in_progress_count, :efforts_in_progress, to: :live_event
  delegate :name, :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object
  # past_due_threshold is number of minutes (int or string)

  def initialize(event, past_due_threshold = nil)
    @event = event
    @live_event = LiveEvent.new(event)
    @past_due_threshold = past_due_threshold.present? ? past_due_threshold.to_i : 60
  end

  def event_name
    name
  end

  def course_name
    course.name
  end

  def race_name
    race.try(:name)
  end

  def efforts_past_due_count
    past_due_progress_rows.size
  end

  def past_due_progress_rows
    live_efforts_in_progress.select { |le| le.over_under_due > past_due_threshold.minutes }.sort_by(&:over_under_due).reverse
  end

  def live_efforts_in_progress
    live_efforts.select { |live_effort| efforts_in_progress.map(&:id).include?(live_effort.id)}
  end
end