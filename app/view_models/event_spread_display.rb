class EventSpreadDisplay

  attr_reader :event, :splits, :display_style
  delegate :name, :start_time, :course, :race, :available_live, :beacon_url, :simple?, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params should include
  # params[:style] (elapsed / ampm / military / segment) and
  # params[:sort] (place / bib / first / last)

  def initialize(event, params = {})
    @event = event
    @splits = event.ordered_splits.to_a
    @display_style = params[:style]
    @split_times_data_by_effort = event.split_times
                                      .pluck_to_hash(:effort_id, :time_from_start, :split_id, :sub_split_bitkey, :data_status)
                                      .group_by { |row| row[:effort_id] }
    @efforts = event.efforts.sorted_with_finish_status
    @sort_method = params[:sort]
  end

  def effort_times_rows
    @effort_times_rows ||=
        sorted_efforts.map { |effort| EffortTimesRow.new(effort, relevant_splits, split_times_data_by_effort[effort.id],
                                                         event_start_time) }
  end

  def efforts_count
    efforts.size
  end

  def course_name
    course.name
  end

  def race_name
    race.try(:name)
  end

  def event_start_time
    @event_start_time ||= event.start_time
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
    @relevant_splits ||= %w(ampm military).include?(display_style) ? splits : splits_without_start
  end

  private

  attr_reader :efforts, :split_times_data_by_effort, :sort_method

  def sorted_efforts
    @sorted_efforts ||=
        case sort_method
        when 'bib'
          efforts.sort_by(&:bib_number)
        when 'last'
          efforts.sort_by(&:last_name)
        when 'first'
          efforts.sort_by(&:first_name)
        else
          efforts
        end
  end

  def splits_without_start
    splits[1..-1]
  end
end