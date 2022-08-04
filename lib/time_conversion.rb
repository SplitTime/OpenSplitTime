class TimeConversion
  HMS_FORMAT = /\A-?\d+:\d{2}(:\d{2})?(\.\d+)?\z/.freeze
  MILITARY_FORMAT = /\A([0-1]\d|2[0-3]|[0-9]):([0-5]\d)(:[0-5]\d)?\z/.freeze

  def self.hms_to_seconds(hms)
    return nil unless hms.present?
    raise ArgumentError, "Improper hms time format: #{hms}" unless hms =~ HMS_FORMAT

    negative = hms.start_with?("-")
    components = hms.sub(/\A-/, "").split(":")
    milliseconds_present = components.last.include?(".")
    numeric_method = milliseconds_present ? :to_f : :to_i
    units = %w[hours minutes seconds]
    seconds = components.zip(units).map { |component, unit| component.send(numeric_method).send(unit) }
        .sum.send(numeric_method)
    negative ? -seconds : seconds
  end

  def self.seconds_to_hms(seconds_elapsed, options = {})
    return "" unless seconds_elapsed
    return "--:--:--" if options[:blank_zero] && seconds_elapsed == 0

    to_hms(seconds_elapsed / 1.hour,
           (seconds_elapsed / 1.minute) % 1.minute,
           seconds_elapsed % 1.minute)
  end

  def self.absolute_to_hms(absolute)
    return "" unless absolute.present?

    I18n.localize(absolute, format: :military)
  end

  def self.components_to_absolute(components)
    DateTime.new(components["date(1i)"].to_i,
                 components["date(2i)"].to_i,
                 components["date(3i)"].to_i,
                 components["date(4i)"].to_i,
                 components["date(5i)"].to_i)
  end

  def self.to_hms(hours, minutes, seconds)
    hundredths = (seconds % 1 * 100).to_i
    if seconds.is_a?(Integer)
      format("%02d:%02d:%02d", hours, minutes, seconds)
    else
      format("%02d:%02d:%02d.%02d", hours, minutes, seconds, hundredths)
    end
  end

  # Converts attempted military times like "12:45:ss" to real military times i.e. "12:45:00".
  # Pads with `0` where needed, i.e. "5:33" => 05:33:00.
  # Also converts timestamps like "2022-07-15 15:45:00-0600" to military times i.e. "15:45:00".
  #
  # Returns nil when the argument does not match either pattern.
  def self.user_entered_to_military(time_string)
    return if time_string.blank? || time_string.length < 3

    subbed_string = time_string.gsub(/[a-zA-Z]/, "0")
    hours, minutes, seconds = subbed_string.split(":")
    new_string = [hours, minutes, seconds].map do |component|
      component ||= ""
      component.rjust(2, "0")
    end.join(":")

    return new_string if valid_military?(new_string)
    return if invalid_military?(new_string)

    datetime = time_string.to_datetime rescue Date::Error
    return absolute_to_hms(datetime) if datetime.present?
  end

  def self.invalid_military?(military)
    military.present? && military.length == 8
  end

  def self.valid_military?(military)
    MILITARY_FORMAT === military
  end
end
