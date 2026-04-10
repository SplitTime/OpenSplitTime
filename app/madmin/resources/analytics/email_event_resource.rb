module Analytics
  class EmailEventResource < Madmin::Resource
    # Attributes
    attribute :id, form: false
    attribute :email, index: true
    attribute :event, index: true
    attribute :timestamp, index: true
    attribute :status, index: true
    attribute :reason, index: true
    attribute :type, index: true
    attribute :response, index: false
    attribute :ip, index: false
    attribute :useragent, index: false
    attribute :smtp_id, index: false
    attribute :category, index: false
    attribute :event_type, index: false
    attribute :provider_event_id, index: false
    attribute :provider_message_id, index: false
    attribute :created_at, form: false, index: true
    attribute :updated_at, form: false, index: false

    # Associations

    def self.default_sort_column
      "created_at"
    end

    def self.default_sort_direction
      "desc"
    end
  end
end
