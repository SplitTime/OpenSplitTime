module ApplicationHelper
  # include TimeFormats

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