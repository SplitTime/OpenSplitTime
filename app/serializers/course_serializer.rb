class CourseSerializer < BaseSerializer
  attributes :id, :name, :description, :editable

  has_many :splits
end