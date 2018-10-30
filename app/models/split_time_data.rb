# frozen_string_literal: true

# This Struct is a lightweight alternative to SplitTime when many objects are needed.
# The methods that convert between time zones in Rails are slow and create an unacceptable delay
# when working with many objects, particularly in a full spread view. SplitTimeData is designed to receive
# both an absolute_time string and a localized (day_and_time) string from the database query,
# both of which it converts to DateTime objects as absolute_time and day_and_time
# for consistency with the SplitTime model.

SplitTimeData = Struct.new(:id, :effort_id, :lap, :split_id, :bitkey, :stopped_here, :pacer, :data_status_numeric, :absolute_time_string,
                           :day_and_time_string, :time_from_start, :segment_time, :military_time, keyword_init: true) do

  def absolute_time
    absolute_time_string&.to_datetime
  end

  def day_and_time
    day_and_time_string&.to_datetime
  end

  def data_status
    SplitTime.data_statuses.invert[data_status_numeric]
  end

  def stopped_here?
    stopped_here
  end

  def time_point
    TimePoint.new(lap, split_id, bitkey)
  end
end
