# frozen_string_literal: true

module ApplicationHelper
  include TimeFormats
  include MeasurementFormats

  def day_time_current_military_full(zone)
    l(Time.current.in_time_zone(zone), format: :full_day_military_and_zone)
  end

  def humanize_boolean(boolean)
    case boolean
    when false
      'No'
    when true
      'Yes'
    else
      nil
    end
  end
end
