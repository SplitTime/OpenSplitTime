# frozen_string_literal: true

SplitTimeData = Struct.new(:effort_id, :lap, :split_id, :sub_split_bitkey, :stopped_here,
                      :absolute_time, :day_and_time, :time_from_start, :segment_time) do

  def stopped_here?
    stopped_here
  end
end
