# frozen_string_literal: true

Projection = Struct.new(:lap, :split_id, :sub_split_bitkey, :effort_count, :low_ratio, :average_ratio, :high_ratio,
                        :low_seconds, :average_seconds, :high_seconds, keyword_init: true) do

  def time_point
    TimePoint.new(lap, split_id, bitkey)
  end

  def bitkey
    sub_split_bitkey
  end
end
