class EventSpreadDisplay

  attr_reader :event, :splits, :effort_times_rows, :display_style
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
    sort_efforts(params[:sort_by])
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

  def display_style_text
    case display_style
      when 'segment'
        'Segment times'
      when 'time_of_day'
        'Time of Day'
      when 'military'
        'Military'
      else
        'Elapsed times'
    end
  end

  def relevant_splits
    display_style == 'time_of_day' ? splits : splits_without_start
  end

  private

  attr_reader :efforts, :split_times

  def sort_efforts(sort_by)
    efforts.sort_by!(&:place) if sort_by == 'place'
    efforts.sort_by!(&:bib_number) if sort_by == 'bib'
    efforts.sort_by!(&:last_name) if sort_by == 'last'
    efforts.sort_by!(&:first_name) if sort_by == 'first'
  end

  def create_effort_times_rows
    efforts.each do |effort|
      effort_times_row = EffortTimesRow.new(effort,
                                            relevant_splits,
                                            split_times[effort.id],
                                            start_time: event.start_time)
      effort_times_rows << effort_times_row
    end
  end

  def splits_without_start
    splits[1..-1]
  end

end