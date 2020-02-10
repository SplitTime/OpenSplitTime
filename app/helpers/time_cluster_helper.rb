# frozen_string_literal: true

module TimeClusterHelper
  def time_cluster_display_data(cluster, display_style, options = {})
    with_status = options[:with_status]
    formatted_times = time_cluster_data(cluster, display_style).map { |time| cluster_display_formatted_time(time, cluster, display_style) || '--:--:--' }

    content_tag(:div) do
      if with_status
        time_array = formatted_times.zip(cluster.time_data_statuses)

        time_array.map.with_index(1) do |(formatted_time, status), i|
          concat text_with_status_indicator(formatted_time, status)
          concat ' / ' unless i == time_array.size
        end
      else
        concat formatted_times.join(' / ')
      end

      if cluster.show_stop_indicator?
        concat ' '
        concat fa_icon('hand-paper', class: 'text-danger has-tooltip', data: {toggle: 'tooltip', 'original-title' => 'Stopped Here'})
      end
    end
  end

  def time_cluster_export_data(cluster, display_style)
    time_cluster_data(cluster, display_style)
      .map { |time| cluster_export_formatted_time(time, cluster, display_style) }
  end

  def time_cluster_data(cluster, display_style)
    case display_style.to_sym
    when :segment
      cluster.aid_time_recordable? ? [cluster.segment_time, cluster.time_in_aid] : [cluster.segment_time]
    when :ampm
      cluster.absolute_times_local
    when :military
      cluster.absolute_times_local
    when :early_estimate
      cluster.absolute_estimates_early_local
    when :late_estimate
      cluster.absolute_estimates_late_local
    else
      cluster.times_from_start
    end
  end

  def cluster_display_formatted_time(time, cluster, display_style)
    case display_style.to_sym
    when :segment
      cluster.finish? ? time_format_xxhyymzzs(time) : time_format_xxhyym(time)
    when :ampm
      cluster.finish? ? day_time_format_hhmmss(time) : day_time_format(time)
    when :military
      cluster.finish? ? day_time_military_format_hhmmss(time) : day_time_military_format(time)
    when :early_estimate
      cluster.finish? ? day_time_format_hhmmss(time) : day_time_format(time)
    when :late_estimate
      cluster.finish? ? day_time_format_hhmmss(time) : day_time_format(time)
    else
      cluster.finish? ? time_format_hhmmss(time) : time_format_hhmm(time)
    end
  end

  def cluster_export_formatted_time(time, cluster, display_style)
    case display_style.to_sym
    when :segment
      time ? time_format_hhmmss(time) : ''
    when :ampm
      time ? day_time_format_hhmmss(time) : ''
    when :military
      time ? day_time_military_format_hhmmss(time) : ''
    else
      time ? time_format_hhmmss(time) : ''
    end
  end
end
