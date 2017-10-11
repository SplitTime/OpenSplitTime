class CourseParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :description, :next_start_time, splits_attributes: [*SplitParameters.permitted]]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
