# frozen_string_literal: true

# This Struct is a lightweight alternative to SplitTime when many objects are needed.

SplitTimeData = Struct.new(:id, :effort_id, :lap, :split_id, :bitkey, :stopped_here, :data_status_numeric,
                           :absolute_time_string, :day_and_time_string, :time_from_start, :segment_time, keyword_init: true) do

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
