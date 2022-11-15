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
      city
      state_code
      country_code
      course_name
      year
      elapsed_time
      finish_count
    ]
  end
end
