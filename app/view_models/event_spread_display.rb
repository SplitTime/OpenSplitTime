class EventSpreadDisplay

  attr_reader :event, :display_style
  delegate :name, :start_time, :course, :organization, :available_live, :beacon_url, :simple?, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params may include
  # params[:style] (elapsed / ampm / military / segment) and
  # params[:sort] (overall_rank, gender_rank, bib_number, first_name, last_name, or any other sortable attribute)

  def initialize(event, params = {})
    @event = event
    @display_style = params[:style].presence || (event.available_live ? 'ampm' : 'elapsed')
    @sort_columns = params[:sort].to_s.split(',')
  end

  def split_header_data
    lap_splits.map { |lap_split| {title: header_name(lap_split),
                                  extensions: header_extensions(lap_split),
                                  distance: lap_split.distance_from_start} }
  end

  def segment_total_header_data
    {title: aid_times_recorded? ? 'Totals' : 'Total',
     extensions: aid_times_recorded? ? %w(Segment Aid) : []}
  end

  def aid_times_recorded?
    lap_splits.any? { |lap_split| lap_split.name_extensions.size > 1 }
  end

  def show_segment_totals?
    display_style == 'segment'
  end

  def effort_times_rows
    @effort_times_rows ||=
        efforts.map { |effort| EffortTimesRow.new(effort: effort, lap_splits: lap_splits,
                                                  split_times: split_times_by_effort[effort.id]) }
  end

  def efforts_count
    efforts.size
  end

  def course_name
    course.name
  end

  def organization_name
    organization.try(:name)
  end

  def event_start_time
    @event_start_time ||= event.start_time
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(highest_lap)
  end

  private

  attr_reader :sort_columns
  delegate :multiple_laps?, to: :event

  def split_times_by_effort
    @split_times_by_effort ||= split_times.group_by(&:effort_id)
  end

  def split_times
    @split_times ||=
        event.split_times.struct_pluck(:effort_id, :lap, :split_id, :sub_split_bitkey, :time_from_start, :stopped_here)
  end

  def efforts
    @efforts ||= event.efforts.ranked_with_finish_status(order_by: sort_columns)
  end

  def header_name(lap_split)
    multiple_laps? ? lap_split.base_name : lap_split.base_name_without_lap
  end

  def header_extensions(lap_split)
    extension_components = display_style == 'segment' ? %w(Segment Aid) : lap_split.name_extensions
    lap_split.name_extensions.size > 1 ? extension_components : []
  end

  def highest_lap
    split_times.map(&:lap).max || 1
  end
end