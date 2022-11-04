# frozen_string_literal: true

class BestEffortSegment < ::ApplicationRecord
  include TimeZonable
  include PersonalInfo
  include DatabaseRankable

  enum gender: [:male, :female]
  belongs_to :course
  belongs_to :effort

  zonable_attribute :begin_time

  scope :for_courses, -> (courses) { where(course_id: courses) }
  scope :full_course, -> { where(full_course: true) }
  scope :for_efforts, -> (efforts) { where(effort_id: efforts) }
  scope :over_segment, lambda { |segment|
    where(begin_split_id: segment.begin_id,
          begin_bitkey: segment.begin_bitkey,
          end_split_id: segment.end_id,
          end_bitkey: segment.end_bitkey)
  }

  def course_name
    course.name
  end

  def ends_at_finish?
    end_split_kind == Split.kinds[:finish]
  end

  def to_param
    slug
  end

  def year_and_lap
    lap_string = multiple_laps? ? "Lap #{lap}" : nil
    [begin_time_local.year, lap_string].compact.join(" / ")
  end
end
