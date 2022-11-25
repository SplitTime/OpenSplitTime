# frozen_string_literal: true

class BestEffortSegmentParameters < BaseParameters
  def self.csv_export_attributes
    %w[
      overall_rank
      gender_rank
      first_name
      last_name
      gender
      age
      age_group
      age_group_rank
      city
      state_code
      country_code
      course_name
      year
      place
      elapsed_time
      finish_count
    ]
  end
end
