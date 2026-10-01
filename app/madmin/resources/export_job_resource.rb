class ExportJobResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :status, index: true
  attribute :source_url
  attribute :started_at, index: true
  attribute :elapsed_time, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :controller_name
  attribute :resource_class_name, index: true
  attribute :sql_string
  attribute :error_message
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
