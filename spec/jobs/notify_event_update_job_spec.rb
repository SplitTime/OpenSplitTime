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
    let(:successful_response) { Interactors::Response.new([], "Published", {}) }
    let(:unsuccessful_response) do
      Interactors::Response.new([{ title: "boom", detail: { messages: ["nope"] } }], "boom", {})
    end

    before { allow(EventUpdateNotifier).to receive(:publish).and_return(successful_response) }

    it "sends a message to EventUpdateNotifier" do
      expect(EventUpdateNotifier).to receive(:publish)
        .with(topic_arn: event.topic_resource_key, event: event, subscribable: event)
      perform_notification
    end

    context "when EventUpdateNotifier returns a successful self-healed response" do
      before { allow(EventUpdateNotifier).to receive(:publish).and_return(successful_response) }

      it "does not raise (no retry loop)" do
        expect { perform_notification }.not_to raise_error
      end
    end

    context "when EventUpdateNotifier returns an unsuccessful response" do
      before { allow(EventUpdateNotifier).to receive(:publish).and_return(unsuccessful_response) }

      it "raises so Solid Queue retries" do
        expect { perform_notification }.to raise_error(/Failed to send event update notification/)
      end
    end
  end
end
