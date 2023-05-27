class CourseResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :description
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :next_start_time
  attribute :slug
  attribute :concealed
  attribute :track_points
  attribute :gpx, index: false

  # Associations
  attribute :slugs
  attribute :versions
  attribute :organization
  attribute :course_group_courses
  attribute :course_groups
  attribute :events
  attribute :splits

  # Uncomment this to customize the display name of records in the admin area.
  # def self.display_name(record)
  #   record.name
  # end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
