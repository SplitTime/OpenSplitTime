class EventProgressDisplay

  attr_reader :event, :progress_event, :past_due_threshold
  delegate :progress_efforts, :efforts_started_count, :efforts_finished_count, :efforts_dropped_count,
           :efforts_in_progress_count, to: :progress_event
  delegate :name, :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object
  # past_due_threshold is number of minutes (int or string)

  def initialize(event, past_due_threshold = nil)
    @event = event
    @progress_event = ProgressEvent.new(event)
    @past_due_threshold = past_due_threshold.present? ? past_due_threshold.to_i : 60
  end

  def event_name
    name
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  def efforts_past_due_count
    past_due_progress_rows.count
  end

  def past_due_progress_rows
    progress_efforts.select { |pe| pe.over_under_due > past_due_threshold.minutes }.sort_by(&:over_under_due).reverse
  end

end