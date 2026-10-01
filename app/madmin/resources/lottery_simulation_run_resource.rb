class LotterySimulationRunResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :context
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :requested_count, form: false
  attribute :status, index: true
  attribute :error_message
  attribute :success_count, form: false, index: true
  attribute :failure_count, form: false, index: true
  attribute :started_at
  attribute :elapsed_time, index: true

  # Associations
  attribute :lottery, index: true
  attribute :simulations

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
