class EventSpreadDisplay
  STYLES_WITH_START_TIME = %w(ampm military)

  attr_reader :event, :display_style
  delegate :name, :start_time, :course, :race, :available_live, :beacon_url, :simple?, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params should include
  # params[:style] (elapsed / ampm / military / segment) and
  # params[:sort] (place / bib / first / last)

  def initialize(event, params = {})
    @event = event
    @display_style = params[:style]
    @sort_method = params[:sort]
  end

  def relevant_lap_splits
    @relevant_lap_splits ||= STYLES_WITH_START_TIME.include?(display_style) ? lap_splits : lap_splits_without_start
  end

  def effort_times_rows
    @effort_times_rows ||=
        sorted_efforts.map { |effort| EffortTimesRow.new(effort, relevant_lap_splits, split_times_data_by_effort[effort.id]) }
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

  def to_csv
    CSV.generate do |csv|
      csv << ['Under construction']
    end
  end

  private

  attr_reader :sort_method

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(highest_lap)
  end

  def split_times_data_by_effort
    @split_times_data_by_effort ||=
        split_times_data.group_by { |row| row[:effort_id] }
  end

  def split_times_data
    @split_times_data ||=
        event.split_times
            .pluck_to_hash(:effort_id, :time_from_start, :lap, :split_id, :sub_split_bitkey, :data_status)
  end

  def efforts
    @efforts ||= event.efforts.sorted_with_finish_status
  end

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

  def lap_splits_without_start
    lap_splits.reject(&:start?)
  end

  def highest_lap
    split_times_data.max_by { |row| row[:lap] }[:lap]
  end
end