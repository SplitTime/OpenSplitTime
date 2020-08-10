# frozen_string_literal: true

class BestEffortSegment < ::ApplicationRecord
  include DatabaseRankable, PersonalInfo

  enum gender: [:male, :female]

  scope :for_efforts, -> (efforts) { where(effort_id: efforts) }
  scope :over_segment, -> (segment) do
    where(begin_split_id: segment.begin_id,
          begin_bitkey: segment.begin_bitkey,
          end_split_id: segment.end_id,
          end_bitkey: segment.end_bitkey)
  end

  def to_param
    slug
  end

  def year_and_lap
    lap_string = multiple_laps? ? "Lap #{lap}" : nil
    [begin_time.in_time_zone(home_time_zone).year, lap_string].compact.join(" / ")
  end
end
