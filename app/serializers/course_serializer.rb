class CourseSerializer < BaseSerializer
  attributes :id, :name, :description

  has_many :splits
end