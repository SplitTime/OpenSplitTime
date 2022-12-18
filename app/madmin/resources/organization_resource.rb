class OrganizationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :description
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :updated_by
  attribute :concealed
  attribute :slug

  # Associations
  attribute :slugs
  attribute :versions
  attribute :courses
  attribute :course_groups
  attribute :event_groups
  attribute :lotteries
  attribute :stewardships
  attribute :stewards
  attribute :event_series
  attribute :results_templates

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
