# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyEventUpdateJob do
  subject { described_class.new }

  let(:event_id) { event.id }
  let(:event) { events(:rufa_2017_24h) }
  before { event.update(topic_resource_key: "aws_mock_key") }

  describe "#perform" do
    let(:perform_notification) { subject.perform(event_id) }
    let(:successful_response) { Interactors::Response.new(errors: []) }
    let(:unsuccessful_response) { Interactors::Response.new(errors: ["There was an error"]) }

    before { allow(EventUpdateNotifier).to receive(:publish).and_return(successful_response) }

    it "sends a message to EventUpdateNotifier" do
      expect(EventUpdateNotifier).to receive(:publish).with(topic_arn: "aws_mock_key", event: event)
      perform_notification
    end
  end
end
