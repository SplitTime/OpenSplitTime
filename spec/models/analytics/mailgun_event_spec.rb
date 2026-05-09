require "rails_helper"

RSpec.describe ::Analytics::MailgunEvent do
  it "inherits from EmailEvent" do
    expect(described_class.superclass).to eq(Analytics::EmailEvent)
  end

  it "sets type automatically via STI" do
    event = described_class.new
    expect(event.type).to eq("Analytics::MailgunEvent")
  end

  it "aliases mailgun_event_id to provider_event_id" do
    event = described_class.new(mailgun_event_id: "abc123")
    expect(event.provider_event_id).to eq("abc123")
  end

  it "aliases mailgun_message_id to provider_message_id" do
    event = described_class.new(mailgun_message_id: "msg456")
    expect(event.provider_message_id).to eq("msg456")
  end

  it "aliases recipient to email" do
    event = described_class.new(recipient: "user@example.com")
    expect(event.email).to eq("user@example.com")
  end
end
