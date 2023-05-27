class NotificationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :distance
  attribute :bitkey
  attribute :follower_ids
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :kind
  attribute :topic_resource_key
  attribute :subject
  attribute :notice_text

  # Associations
  attribute :effort
  attribute :event

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
