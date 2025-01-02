require "rails_helper"

RSpec.describe NotifyEventUpdateJob do
  subject { described_class.new }

  let(:event_id) { event.id }
  let(:event) { events(:rufa_2017_24h) }

  before do
    event.assign_topic_resource
    event.save!
  end

  describe "#perform" do
    let(:perform_notification) { subject.perform(event_id) }
    let(:successful_response) { Interactors::Response.new(errors: []) }
    let(:unsuccessful_response) { Interactors::Response.new(errors: ["There was an error"]) }

    before { allow(EventUpdateNotifier).to receive(:publish).and_return(successful_response) }

    it "sends a message to EventUpdateNotifier" do
      expect(EventUpdateNotifier).to receive(:publish).with(topic_arn: event.topic_resource_key, event: event)
      perform_notification
    end
  end
end
