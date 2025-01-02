require "rails_helper"

RSpec.describe ::Analytics::SendgridEvent do
  describe "#timestamp=" do
    let(:sendgrid_event) { described_class.new(timestamp: timestamp) }

    context "when provided an integer" do
      let(:timestamp) { 1683409840 }

      it { expect(sendgrid_event.timestamp).to eq(Time.at(timestamp)) }
    end

    context "when provided a timestamp as a string" do
      let(:timestamp) { "1683409840" }

      it { expect(sendgrid_event.timestamp).to eq(Time.at(timestamp.to_i)) }
    end

    context "when provided a string" do
      let(:timestamp) { "2023-01-01 12:00:00" }

      it { expect(sendgrid_event.timestamp).to eq("2023-01-01 12:00:00") }
    end

    context "when provided a datetime" do
      let(:timestamp) { "2023-01-01 12:00:00".in_time_zone }

      it { expect(sendgrid_event.timestamp).to eq("2023-01-01 12:00:00") }
    end
  end
end
