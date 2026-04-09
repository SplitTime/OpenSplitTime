require "rails_helper"

RSpec.describe ::Analytics::SendgridEvent do
  it "inherits from EmailEvent" do
    expect(described_class.superclass).to eq(Analytics::EmailEvent)
  end

  it "defaults provider to sendgrid" do
    expect(described_class.new.provider).to eq("sendgrid")
  end

  it "aliases sg_event_id to provider_event_id" do
    event = described_class.new(sg_event_id: "abc123")
    expect(event.provider_event_id).to eq("abc123")
  end

  it "aliases sg_message_id to provider_message_id" do
    event = described_class.new(sg_message_id: "msg456")
    expect(event.provider_message_id).to eq("msg456")
  end
end
