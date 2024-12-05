class LotteryEntrantResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :lottery_division_id
  attribute :first_name
  attribute :last_name
  attribute :gender
  attribute :number_of_tickets
  attribute :birthdate
  attribute :city
  attribute :state_code
  attribute :country_code
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :state_name
  attribute :country_name
  attribute :pre_selected
  attribute :external_id
  attribute :withdrawn
  attribute :service_completed_date

  # Associations
  attribute :division
  attribute :tickets
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
