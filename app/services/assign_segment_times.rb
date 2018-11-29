#frozen_string_literal: true

class AssignSegmentTimes
  def self.perform!(ordered_split_times, source_attribute = :absolute_time)
    ordered_split_times.each_cons(2) do |previous_split_time, split_time|
      earlier_time = previous_split_time.send(source_attribute)
      later_time = split_time.send(source_attribute)
      split_time.segment_time = earlier_time && later_time && later_time - earlier_time
    end
  end
end
