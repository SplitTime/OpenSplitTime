class ResultsTemplateCategoryResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :position, index: true
  attribute :fixed_position, index: true

  # Associations
  attribute :template, index: true
  attribute :category, index: true

  # Uncomment this to customize the display name of records in the admin area.
  def self.display_name(record)
    "#{record.results_template.slug}/#{record.results_category.slug}"
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
