module Live::EventsHelper
  def display_progress_info(args)
    split_name = args[:split_name]
    day_and_time = args[:day_and_time]

    if split_name && day_and_time
      "#{split_name} at #{l(day_and_time, format: :day_and_military) }"
    elsif split_name
      "#{split_name} at [unknown time]"
    else
      '[None]'
    end
  end

  def display_progress_time_only(args)
    day_and_time = args[:day_and_time]
    day_and_time ? l(day_and_time, format: :day_and_military) : '[unknown time]'
  end

  def join_days_and_times(days_and_times)
    days_and_times.map { |day_and_time| day_time_military_format(day_and_time) }.join(' / ')
  end
end