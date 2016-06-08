class EventSpreadDisplay

  attr_reader :event, :display_style, :splits, :effort_times_rows
  delegate :name, :start_time, :course, :race, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:style] (elapsed / time-of-day / segment)

  def initialize(event, params = {})
    @event = event
    @splits = event.ordered_splits.to_a
    @display_style = params[:style]
    @split_times = @event.split_times.group_by(&:effort_id)
    @efforts = @event.efforts.sorted_with_finish_status
    @effort_times_rows = []
    create_effort_times_rows
  end

  def efforts_count
    efforts.count
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  private

  attr_reader :efforts, :split_times

  def create_effort_times_rows
    efforts.each do |effort|
      effort_times_row = EffortTimesRow.new(effort,
                                            splits,
                                            split_times[effort.id],
                                            start_time: event.start_time)
      effort_times_rows << effort_times_row
    end
  end

end