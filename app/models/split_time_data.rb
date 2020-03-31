# frozen_string_literal: true

# This Struct is a lightweight alternative to SplitTime when many objects are needed.
# The time zone parsing methods in Rails are slow and create an unacceptable delay
# when working with many objects, particularly in a full spread view.

# SplitTimeData receives both a non-localized absolute_time_string and a localized
# absolute_time_local_string from the database query.

SplitTimeData = Struct.new(:id, :effort_id, :lap, :split_id, :bitkey, :stopped_here, :pacer, :data_status_numeric,
                           :absolute_time_string, :absolute_time_local_string, :time_from_start, :segment_time,
                           :military_time, keyword_init: true) do

  include TimePointMethods

  # absolute_time is an ActiveSupport::TimeWithZone for compatibility and useful math operations.
  def absolute_time
    absolute_time_string&.in_time_zone('UTC')
  end

  # absolute_time_local is a Ruby DateTime object for speed of conversion.
  # The events/spread view relies on this attribute and slows unacceptably
  # when it is parsed into an ActiveSupport::TimeWithZone object.
  def absolute_time_local
    absolute_time_local_string&.to_datetime
  end

  def data_status
    SplitTime.data_statuses.invert[data_status_numeric]
  end

  def stopped_here?
    stopped_here
  end
end
