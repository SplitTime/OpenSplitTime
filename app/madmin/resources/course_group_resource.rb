class CourseGroupResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :slug, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :slugs
  attribute :versions
  attribute :organization, index: true
  attribute :course_group_courses
  attribute :courses
  attribute :events

  def self.display_name(record)
    record.name
  end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
