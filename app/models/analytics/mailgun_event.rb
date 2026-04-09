module ::Analytics
  class MailgunEvent < EmailEvent
    alias_attribute :mailgun_event_id, :provider_event_id
    alias_attribute :mailgun_message_id, :provider_message_id
    alias_attribute :recipient, :email
  end
end
