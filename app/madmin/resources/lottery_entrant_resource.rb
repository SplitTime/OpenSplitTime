class LotteryEntrantResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :lottery_division_id
  attribute :first_name, index: true
  attribute :last_name, index: true
  attribute :gender, index: true
  attribute :number_of_tickets, index: true
  attribute :birthdate
  attribute :city
  attribute :state_code
  attribute :country_code
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :state_name
  attribute :country_name
  attribute :pre_selected, index: true
  attribute :external_id
  attribute :drawn_at, index: true
  attribute :withdrawn, index: true

  # Associations
  attribute :division, index: true
  attribute :tickets
  attribute :person

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
