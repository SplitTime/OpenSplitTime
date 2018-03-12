# frozen_string_literal: true

class CourseParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :description, :next_start_time, :gpx, :delete_gpx, splits_attributes: [*SplitParameters.permitted]]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
