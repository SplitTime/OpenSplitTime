class CourseSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  has_many :splits
end
