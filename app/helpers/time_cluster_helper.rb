# frozen_string_literal: true

module TimeClusterHelper

  def time_cluster_display_data(cluster, display_style)
    time_cluster_data(cluster, display_style)
        .map { |time| cluster_display_formatted_time(time, cluster, display_style) }.join(' / ')
  end

  def time_cluster_export_data(cluster, display_style)
    time_cluster_data(cluster, display_style)
        .map { |time| cluster_export_formatted_time(time, cluster, display_style) }
  end

  def time_cluster_data(cluster, display_style)
    case display_style
    when 'segment'
      cluster.aid_time_recordable? ? [cluster.segment_time, cluster.time_in_aid] : [cluster.segment_time]
    when 'ampm'
      cluster.days_and_times
    when 'military'
      cluster.days_and_times
    else
      cluster.times_from_start
    end
  end

  def cluster_display_formatted_time(time, cluster, display_style)
    case display_style
    when 'segment'
      cluster.finish? ? time_format_xxhyymzzs(time) : time_format_xxhyym(time)
    when 'ampm'
      cluster.finish? ? day_time_format_hhmmss(time) : day_time_format(time)
    when 'military'
      cluster.finish? ? day_time_military_format_hhmmss(time) : day_time_military_format(time)
    else
      cluster.finish? ? time_format_hhmmss(time) : time_format_hhmm(time)
    end
  end

  def cluster_export_formatted_time(time, cluster, display_style)
    case display_style
    when 'segment'
      time ? time_format_hhmmss(time) : ''
    when 'ampm'
      time ? day_time_format_hhmmss(time) : ''
    when 'military'
      time ? day_time_military_format_hhmmss(time) : ''
    else
      time ? time_format_hhmmss(time) : ''
    end
  end
end
