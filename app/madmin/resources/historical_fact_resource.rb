class HistoricalFactResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :kind
  attribute :quantity
  attribute :comments
  attribute :first_name
  attribute :last_name
  attribute :birthdate
  attribute :gender
  attribute :address
  attribute :city
  attribute :state_code
  attribute :country_code
  attribute :state_name
  attribute :country_name
  attribute :email
  attribute :phone
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by

  # Associations
  attribute :organization
  attribute :person

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
