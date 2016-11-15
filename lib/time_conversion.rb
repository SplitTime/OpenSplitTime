module TimeConversion

  def self.hms_to_seconds(hms)
    units = %w(hours minutes seconds)
    hms.present? ?
        hms.split(':')
            .map.with_index { |x, i| x.to_i.send(units[i]) }
            .reduce(:+).to_i : nil
  end

  def self.seconds_to_hms(seconds_elapsed)
    seconds_elapsed ? to_hms(seconds_elapsed / 1.hour,
                             (seconds_elapsed / 1.minute) % 1.minute,
                             seconds_elapsed % 1.minute) : ''
  end

  def self.absolute_to_hms(absolute)
    return '' unless absolute
    time = absolute.to_time
    to_hms(time.hour, time.min, time.sec)
  end

  def self.hms_to_absolute(hms, base_absolute)
    hms.present? ? base_absolute.in_time_zone + hms_to_seconds(hms) : base_absolute.in_time_zone
  end

  def self.to_hms(hours, minutes, seconds)
    format('%02d:%02d:%02d', hours, minutes, seconds)
  end
end