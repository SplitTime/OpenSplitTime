module ApplicationHelper

  def time_format(total_seconds)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    format("%2d:%02d:%02d", hours, minutes, seconds)
  end

end
