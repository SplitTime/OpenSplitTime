module Analytics
  class SmsInboundMessageResource < Madmin::Resource
    # Attributes
    attribute :id, form: false
    attribute :origination_number, index: true
    attribute :destination_number, index: true
    attribute :message_body, index: true
    attribute :keyword, index: true
    attribute :received_at, index: true
    attribute :sns_message_id, index: false
    attribute :inbound_message_id, index: false
    attribute :created_at, form: false, index: true
    attribute :updated_at, form: false, index: false

    # Associations

    def self.default_sort_column
      "received_at"
    end

    def self.default_sort_direction
      "desc"
    end
  end
end
