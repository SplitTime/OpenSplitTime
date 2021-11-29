# frozen_string_literal: true

class CourseParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :description, :next_start_time, :next_start_time_local, :gpx, :delete_gpx, :organization_id,
     splits_attributes: [*SplitParameters.permitted]]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
