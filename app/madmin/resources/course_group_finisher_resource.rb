class CourseGroupFinisherResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :first_name, index: true
  attribute :last_name, index: true
  attribute :gender, index: true
  attribute :city
  attribute :state_code
  attribute :country_code
  attribute :state_name
  attribute :country_name
  attribute :slug
  attribute :finish_count, form: false, index: true

  # Associations
  attribute :person
  attribute :course_group, index: true

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
