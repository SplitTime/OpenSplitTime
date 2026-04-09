module ::Analytics
  class SendgridEvent < EmailEvent
    alias_attribute :sg_event_id, :provider_event_id
    alias_attribute :sg_message_id, :provider_message_id
  end
end
