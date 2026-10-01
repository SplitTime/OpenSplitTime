class ImportJobResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :parent_type, index: true
  attribute :parent_id, index: true
  attribute :format, index: true
  attribute :status, index: true
  attribute :error_message
  attribute :row_count, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :succeeded_count, form: false, index: true
  attribute :failed_count, form: false, index: true
  attribute :started_at
  attribute :elapsed_time
  attribute :ignored_count, form: false
  attribute :files, index: false

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
