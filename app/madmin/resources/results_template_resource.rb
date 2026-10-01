class ResultsTemplateResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :slug, index: true
  attribute :name
  attribute :aggregation_method, index: true
  attribute :podium_size, index: true
  attribute :point_system
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :slugs
  attribute :organization, index: true
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
