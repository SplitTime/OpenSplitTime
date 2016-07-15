class EventSpreadDisplay

  attr_reader :event, :splits, :effort_times_rows, :display_style
  delegate :name, :start_time, :course, :race, :available_live, :beacon_url, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params should include
  # params[:style] (elapsed / ampm / military / segment) and
  # params[:sort] (place / bib / first / last)

  def initialize(event, params = {})
    @event = event
    @splits = event.ordered_splits.to_a
    @display_style = params[:style]
    @split_times = @event.split_times.group_by(&:effort_id)
    @efforts = @event.efforts.sorted_with_finish_status
    @effort_times_rows = []
    sort_efforts(params[:sort])
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
      when 'ampm'
        'Time of day'
      when 'military'
        'Military time'
      else
        'Elapsed times'
    end
  end

  def relevant_splits
    (display_style == 'ampm') || (display_style == 'military') ? splits : splits_without_start
  end

  def beacon_button_text
    return nil unless beacon_url.present?
    return 'SPOT Page' if beacon_url.include?('findmespot.com')
    return 'FasterTracks' if beacon_url.include?('fastertracks.com')
    return 'SPOT via TrackLeaders' if beacon_url.include?('trackleaders.com')
    'Event Locator Beacon'
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