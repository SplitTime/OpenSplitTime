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

  # change the default link renderer for will_paginate
  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    unless options[:renderer]
      options = options.merge :renderer => WillPaginate::ActionView::Bootstrap4LinkRenderer
    end
    super *[collection_or_options, options].compact
  end
end
