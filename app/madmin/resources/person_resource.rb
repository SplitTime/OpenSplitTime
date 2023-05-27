class PersonResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :first_name
  attribute :last_name
  attribute :gender
  attribute :birthdate
  attribute :city
  attribute :state_code
  attribute :email
  attribute :phone
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :country_code
  attribute :user_id
  attribute :concealed
  attribute :slug
  attribute :topic_resource_key
  attribute :state_name
  attribute :country_name
  attribute :photo, index: false

  # Associations
  attribute :subscriptions
  attribute :followers
  attribute :slugs
  attribute :versions
  attribute :efforts
  attribute :claimant

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
