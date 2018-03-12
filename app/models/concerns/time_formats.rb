# frozen_string_literal: true

module TimeFormats
  extend ActiveSupport::Concern

  def time_format_hhmmss(time_in_seconds)
    time_formatter(time_in_seconds, '%02d:%02d:%02d', 'hms', '--:--:--')
  end

  def time_format_hhmm(time_in_seconds)
    time_formatter(time_in_seconds, '%02d:%02d', 'hm', '--:--')
  end

  def time_format_xxhyymzzs(time_in_seconds)
    if hours(time_in_seconds) == 0
      time_formatter(time_in_seconds, '%02dm%02ds', 'ms', '--:--:--')
    else
      time_formatter(time_in_seconds, '%02dh%02dm%02ds', 'hms', '--:--:--')
    end
  end

  def time_format_xxhyym(time_in_seconds)
    if hours(time_in_seconds) == 0
      time_formatter(time_in_seconds, '%01dm', 'm', '--:--')
    else
      time_formatter(time_in_seconds, '%01dh%02dm', 'hm', '--:--')
    end
  end

  def time_format_minutes(time_in_seconds)
    if true_minutes(time_in_seconds).to_i <= 90
      time_formatter(time_in_seconds, '%1dm', 't', '--')
    else
      time_formatter(time_in_seconds, '%1dh%02dm', 'hm', '--')
    end
  end

  def offset_format_xxhyym(time_in_seconds)
    indicator = time_in_seconds.negative? ? '-' : '+'
    indicator + time_formatter(time_in_seconds, '%02dh%02dm', 'hm', '00:00', false)
  end

  def time_formatter(time_in_seconds, format_string, time_initials, placeholder, negative_parens = true)
    return placeholder if time_in_seconds.nil?
    format_string = "(#{format_string})" if time_in_seconds.to_i.negative? && negative_parens
    format(format_string, *time_components(time_in_seconds, time_initials))
  end

  def time_components(time_in_seconds, time_initials)
    time_initials.chars.map { |initial| time_component_map(time_in_seconds)[initial.to_sym] }
  end

  def time_component_map(time_in_seconds)
    {h: hours(time_in_seconds),
     m: minutes(time_in_seconds),
     t: true_minutes(time_in_seconds),
     s: seconds(time_in_seconds)}
  end

  def hours(time_in_seconds)
    time_in_seconds && (time_in_seconds.abs / (60 * 60)).to_i
  end

  def minutes(time_in_seconds)
    time_in_seconds && ((time_in_seconds.abs / 60) % 60).to_i
  end

  def true_minutes(time_in_seconds)
    time_in_seconds && (time_in_seconds.abs / 60).to_i
  end

  def seconds(time_in_seconds)
    time_in_seconds && (time_in_seconds.abs % 60).to_i
  end

  def day_time_format(datetime)
    datetime ? datetime.strftime('%a %-l:%M%p') : '--:--:--'
  end

  def day_time_format_hhmmss(datetime)
    datetime ? datetime.strftime('%a %-l:%M:%S%p') : '--:--:--'
  end

  def day_time_military_format(datetime)
    datetime ? datetime.strftime('%a %H:%M') : '--- --:--'
  end

  def day_time_military_format_hhmmss(datetime)
    datetime ? datetime.strftime('%a %H:%M:%S') : '--- --:--:--'
  end

  def day_time_full_format(datetime)
    datetime ? datetime.strftime('%B %-d, %Y %l:%M %p') : '--- --:--:--'
  end
end
