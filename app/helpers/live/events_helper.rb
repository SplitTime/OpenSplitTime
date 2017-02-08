module Live::EventsHelper
  def display_progress_info(args)
    split_name = args[:split_name]
    days_and_times = args[:days_and_times]

    split_name ? "#{split_name} at #{join_days_and_times(days_and_times)}" : '[not recorded]'
  end

  def display_progress_times_only(args)
    join_days_and_times(args[:days_and_times])
  end

  def display_progress_in_time_only(args)
    join_days_and_times(args[:days_and_times].first(1))
  end

  def join_days_and_times(days_and_times)
    days_and_times.present? ?
        days_and_times.map { |day_and_time| day_time_military_format(day_and_time) }.join(' / ') : '[not recorded]'
  end
end