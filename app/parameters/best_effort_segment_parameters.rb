# frozen_string_literal: true

class BestEffortSegmentParameters < BaseParameters
  def self.csv_export_attributes
    %i[
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
      year_and_lap
      elapsed_time
    ]
  end
end
