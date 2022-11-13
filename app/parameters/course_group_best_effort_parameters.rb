# frozen_string_literal: true

class CourseGroupBestEffortParameters < BaseParameters
  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
