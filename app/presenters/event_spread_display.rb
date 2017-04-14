class EventSpreadDisplay < EventWithEffortsPresenter
  include ActiveModel::Serialization

  def display_style
    @display_style ||= params[:display_style].presence || (event.available_live ? 'ampm' : 'elapsed')
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
        filtered_ranked_efforts.map { |effort| EffortTimesRow.new(effort: effort,
                                                                  lap_splits: lap_splits,
                                                                  split_times: split_times_by_effort[effort.id],
                                                                  display_style: display_style) }
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(highest_lap)
  end

  private

  delegate :multiple_laps?, to: :event

  def split_times_by_effort
    @split_times_by_effort ||= split_times.group_by(&:effort_id)
  end

  def split_times
    @split_times ||=
        event.split_times.struct_pluck(:effort_id, :lap, :split_id, :sub_split_bitkey, :time_from_start, :stopped_here)
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

  def per_page
    params[:per_page] || ranked_efforts.size
  end
end
