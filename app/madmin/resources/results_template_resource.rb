class ResultsTemplateResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :slug
  attribute :name
  attribute :aggregation_method
  attribute :podium_size
  attribute :point_system
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :slugs
  attribute :organization
  attribute :template_categories
  attribute :categories

  # Uncomment this to customize the display name of records in the admin area.
  def self.display_name(record)
    record.slug
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
