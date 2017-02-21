module SpreadHelper
  def spread_segment_total_data(row)
    row.total_time_in_aid ?
        [time_format_xxhyymzzs(row.total_segment_time), time_format_xxhyym(row.total_time_in_aid)].join(' / ') :
        time_format_xxhyymzzs(row.total_segment_time)
  end

  def segment_total_header
    title = @spread_display.segment_total_header[:title].html_safe + tag(:br)
    extensions = @spread_display.segment_total_header[:extensions].present? ?
        @spread_display.segment_total_header[:extensions].html_safe + tag(:br) : ''
    title + extensions
  end
end