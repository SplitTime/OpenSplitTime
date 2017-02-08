module ApplicationHelper
  include TimeFormats
  include MeasurementFormats

  def day_time_current_military_full
    "#{l(Time.current, format: :full_with_weekday)} at #{l(Time.current, format: :military)}"
  end

  def base_name(split_id)
    Split.find(split_id).base_name
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