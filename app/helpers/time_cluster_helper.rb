module TimeClusterHelper

  def display_cluster(cluster, display_style)
    case display_style
    when 'segment'
      display_segment_cluster(cluster)
    when 'ampm'
      display_ampm_cluster(cluster)
    when 'military'
      display_military_cluster(cluster)
    else
      display_elapsed_cluster(cluster)
    end
  end

  def display_segment_cluster(cluster)
    case
    when cluster.finish?
      time_format_xxhyymzzs(cluster.segment_time)
    when cluster.aid_time_recordable?
      [time_format_xxhyym(cluster.segment_time), time_format_minutes(cluster.time_in_aid)].join(' / ')
    else
      time_format_xxhyym(cluster.segment_time)
    end
  end

  def display_ampm_cluster(cluster)
    if cluster.finish?
      cluster.days_and_times.map { |time| day_time_format_hhmmss(time) }.join(' / ')
    else
      cluster.days_and_times.map { |time| day_time_format(time) }.join(' / ')
    end
  end

  def display_military_cluster(cluster)
    if cluster.finish?
      cluster.days_and_times.map { |time| day_time_military_format_hhmmss(time) }.join(' / ')
    else
      cluster.days_and_times.map { |time| day_time_military_format(time) }.join(' / ')
    end
  end

  def display_elapsed_cluster(cluster)
    if cluster.finish?
      cluster.times_from_start.map { |time| time_format_hhmmss(time) }.join(' / ')
    else
      cluster.times_from_start.map { |time| time_format_hhmm(time) }.join(' / ')
    end
  end
end