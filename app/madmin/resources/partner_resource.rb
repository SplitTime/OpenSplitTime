class PartnerResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :banner_link
  attribute :weight
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :name
  attribute :banner, index: false

  # Associations
  attribute :partnerable
  attribute :versions

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
