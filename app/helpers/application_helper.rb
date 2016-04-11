module ApplicationHelper

  def time_format_hhmmss(time_in_seconds)
    return "" if time_in_seconds.nil?
    seconds = time_in_seconds % 60
    minutes = (time_in_seconds / 60) % 60
    hours = time_in_seconds / (60 * 60)

    format("%2d:%02d:%02d", hours, minutes, seconds)
  end

  def time_format_hhmm(time_in_seconds)
    return "" if time_in_seconds.nil?
    minutes = (time_in_seconds / 60) % 60
    hours = time_in_seconds / (60 * 60)

    format("%2d:%02d", hours, minutes)
  end

  def day_time_format(datetime)
    datetime.strftime("%a %-l:%M%p")
  end

end
