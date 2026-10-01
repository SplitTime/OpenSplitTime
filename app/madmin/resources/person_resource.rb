class PersonResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :first_name, index: true
  attribute :last_name, index: true
  attribute :gender, index: true
  attribute :birthdate, index: true
  attribute :city
  attribute :state_code, index: true
  attribute :email
  attribute :phone
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :country_code
  attribute :user_id
  attribute :concealed, index: true
  attribute :slug
  attribute :state_name
  attribute :country_name
  attribute :photo, index: false

  # Associations
  attribute :slugs
  attribute :versions
  attribute :efforts
  attribute :claimant

  def self.display_name(record)
    record.full_name
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
