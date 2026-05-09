module ::Analytics
  class SmsInboundMessage < ApplicationRecord
    validates :origination_number, :destination_number, :message_body, :received_at, :sns_message_id, presence: true
  end
end
