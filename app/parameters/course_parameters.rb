class CourseParameters < BaseParameters

  def self.permitted
    [:id, :name, :description, :next_start_time, splits_attributes: [*SplitParameters.permitted]]
  end
end
