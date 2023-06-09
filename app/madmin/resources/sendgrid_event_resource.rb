class SendgridEventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :email
  attribute :timestamp
  attribute :smtp_id
  attribute :event
  attribute :category
  attribute :sg_event_id
  attribute :sg_message_id
  attribute :reason
  attribute :status
  attribute :ip
  attribute :response
  attribute :event_type
  attribute :useragent
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations

  # Uncomment this to customize the display name of records in the admin area.
  # def self.display_name(record)
  #   record.name
  # end

  def self.default_sort_column
    "timestamp"
  end

  def self.default_sort_direction
    "desc"
  end
end
