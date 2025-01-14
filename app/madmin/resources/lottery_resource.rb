class LotteryResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :scheduled_start_date
  attribute :slug
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :concealed
  attribute :status
  attribute :calculation_class

  # Associations
  attribute :partners
  attribute :organization
  attribute :divisions
  attribute :entrants
  attribute :tickets
  attribute :simulation_runs
  attribute :slugs

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
