class ImportJobResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :parent_type
  attribute :parent_id
  attribute :format
  attribute :status
  attribute :error_message
  attribute :row_count, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :succeeded_count, form: false
  attribute :failed_count, form: false
  attribute :started_at
  attribute :elapsed_time
  attribute :ignored_count, form: false
  attribute :file, index: false

  # Associations
  attribute :user

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
