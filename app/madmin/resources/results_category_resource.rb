class ResultsCategoryResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :slug
  attribute :name
  attribute :male
  attribute :female
  attribute :nonbinary
  attribute :low_age
  attribute :high_age
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :invalid_efforts, index: false
  attribute :position, index: false
  attribute :fixed_position, index: false

  # Associations
  attribute :organization
  attribute :template_categories
  attribute :templates

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
