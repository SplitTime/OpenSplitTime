class LotteryResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :scheduled_start_date, index: true
  attribute :slug
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :concealed, index: true
  attribute :status, index: true
  attribute :calculation_class

  # Associations
  attribute :partners
  attribute :organization, index: true
  attribute :divisions
  attribute :entrants
  attribute :tickets
  attribute :simulation_runs
  attribute :slugs

  def self.display_name(record)
    record.name
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
