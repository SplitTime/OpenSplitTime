class NotificationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :distance, index: true
  attribute :bitkey
  attribute :follower_ids
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :kind, index: true
  attribute :topic_resource_key
  attribute :subject, index: true
  attribute :notice_text

  # Associations
  attribute :effort, index: true
  attribute :event, index: true

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
