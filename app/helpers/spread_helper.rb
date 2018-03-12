# frozen_string_literal: true

module SpreadHelper
  STYLES_WITH_START_TIME = %w(ampm military)

  def clustered_header(header_data)
    title = header_data[:title].html_safe + tag(:br)
    extensions = header_data[:extensions].present? ? header_data[:extensions].join(' / ').html_safe + tag(:br) : ''
    distance = header_data[:distance].present? ? "(#{pdu('singular').titlecase} #{d(header_data[:distance])})" : ''
    title + extensions + distance
  end

  def clustered_segment_total_header
    clustered_header(@spread_display.segment_total_header_data)
  end

  def clustered_segment_total_data(row)
    row.total_time_in_aid ?
        [time_format_xxhyymzzs(row.total_segment_time), time_format_xxhyym(row.total_time_in_aid)].join(' / ') :
        time_format_xxhyymzzs(row.total_segment_time)
  end

  def individual_headers(header_data)
    title = header_data[:title]
    extensions = header_data[:extensions]
    extensions.present? ? extensions.map { |extension| [title, extension].join(' ') } : [title]
  end

  def individual_segment_total_headers
    individual_headers(@spread_display.segment_total_header_data)
  end

  def individual_segment_total_data(row)
    row.total_time_in_aid ?
        [time_format_hhmmss(row.total_segment_time), time_format_hhmmss(row.total_time_in_aid)] :
        [time_format_hhmmss(row.total_segment_time)]
  end

  def spread_relevant_elements(array)
    STYLES_WITH_START_TIME.include?(@spread_display.display_style) ? array : array[1..-1]
  end

  def spread_export_headers
    spread_export_attributes + spread_individual_split_names +
        (@spread_display.show_segment_totals? ? individual_segment_total_headers : [])
  end

  def spread_export_attributes
    EffortTimesRow::EXPORT_ATTRIBUTES.map { |attr| attr.to_s.humanize }
  end

  def spread_individual_split_names
    split_names = @spread_display.split_header_data.flat_map { |header_data| individual_headers(header_data) }
    split_names[0] = 'Start Offset' if @spread_display.display_style == 'elapsed'
    split_names
  end

  def time_row_export_row(effort_times_row)
    time_row_export_attributes(effort_times_row) + time_row_individual_times(effort_times_row) +
        (@spread_display.show_segment_totals? ? individual_segment_total_data(effort_times_row) : [])
  end

  def time_row_export_attributes(effort_times_row)
    EffortTimesRow::EXPORT_ATTRIBUTES.map { |attr| effort_times_row.send(attr) }
  end

  def time_row_individual_times(effort_times_row)
    times = effort_times_row.time_clusters.flat_map { |tc| time_cluster_export_data(tc, @spread_display.display_style) }
    times[0] = time_format_hhmmss(effort_times_row.start_offset) if @spread_display.display_style == 'elapsed'
    times
  end
end
