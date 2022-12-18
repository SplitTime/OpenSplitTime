class LotterySimulationRunResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :context
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :requested_count, form: false
  attribute :status
  attribute :error_message
  attribute :success_count, form: false
  attribute :failure_count, form: false
  attribute :started_at
  attribute :elapsed_time

  # Associations
  attribute :lottery
  attribute :simulations

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
