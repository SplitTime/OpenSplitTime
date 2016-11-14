module TimeConversion

  def self.hms_to_seconds(hms_elapsed)
    units = %w(hours minutes seconds)
    hms_elapsed.split(':')
        .map.with_index { |x, i| x.to_i.send(units[i]) }
        .reduce(:+).to_i
  end

  def self.seconds_to_hms(seconds_elapsed)
    seconds = seconds_elapsed % 60
    minutes = (seconds_elapsed / 60) % 60
    hours = seconds_elapsed / (60 * 60)
    format('%02d:%02d:%02d', hours, minutes, seconds)
  end

  def absolute_to_hms(absolute)

  end
end