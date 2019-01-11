# frozen_string_literal: true

module TimeClusterHelper
  STATUS_INDICATORS = {bad: %w([* *]), questionable: %w([ ])}.with_indifferent_access

  def time_cluster_display_data(cluster, display_style, options = {})
    with_status = options[:with_status]
    formatted_times = time_cluster_data(cluster, display_style).map { |time| cluster_display_formatted_time(time, cluster, display_style) }

    time_array = if with_status
                   formatted_times.zip(cluster.time_data_statuses).map do |formatted_time, status|
                     brackets = STATUS_INDICATORS.fetch(status, ['', ''])
                     formatted_time ? "#{brackets.first}#{formatted_time}#{brackets.last}" : '--:--:--'
                   end
                 else
                   formatted_times
                 end

    stop_indicator = cluster.show_stop_indicator? ? fa_icon('hand-paper', style: 'color: Tomato') : ''

    content_tag(:div) do
      concat time_array.join(' / ')
      concat ' '
      concat stop_indicator
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
      cluster.days_and_times
    when :military
      cluster.days_and_times
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
