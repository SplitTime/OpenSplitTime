require "rails_helper"

RSpec.describe Analytics::SmsInboundMessage, type: :model do
  subject(:message) do
    described_class.new(
      origination_number: "+13038806481",
      destination_number: "+17626898865",
      message_body: "STOP",
      received_at: Time.current,
      sns_message_id: "abc-123",
    )
  end

  it "is valid with all required attributes" do
    expect(message).to be_valid
  end

  %i[origination_number destination_number message_body received_at sns_message_id].each do |attr|
    it "is invalid without #{attr}" do
      message.send("#{attr}=", nil)
      expect(message).not_to be_valid
      expect(message.errors[attr]).to be_present
    end
  end

  it "rejects duplicate sns_message_id at the database level" do
    message.save!
    duplicate = described_class.new(
      origination_number: "+13038806481",
      destination_number: "+17626898865",
      message_body: "STOP",
      received_at: Time.current,
      sns_message_id: "abc-123",
    )
    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
