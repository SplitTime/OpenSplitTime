require "rails_helper"

RSpec.describe RefreshPendingSubscriptionJob do
  subject(:job) { described_class.new }

  let(:subscription) { subscriptions(:subscription_0003) }
  let(:effort) { subscription.subscribable }

  describe "#perform" do
    context "when the subscription is pending and becomes confirmed after save" do
      before do
        effort.update_column(:topic_resource_key, "arn:aws:sns:us-west-2:123:test-topic")
        subscription.update_columns(resource_key: "pending:#{SecureRandom.uuid}", endpoint: "user@example.com")
        allow(SnsSubscriptionManager).to receive(:locate)
          .and_return(SnsSubscriptionManager::Response.new(subscription_arn: "arn:aws:sns:us-west-2:123:confirmed"))
      end

      it "updates the resource_key to confirmed" do
        job.perform(subscription.id)
        expect(subscription.reload.resource_key).to include("arn:aws:sns")
      end

      it "broadcasts a Turbo Stream refresh" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_refresh_to).with(effort)
        job.perform(subscription.id)
      end
    end

    context "when the subscription is pending but remains pending after save" do
      before do
        effort.update_column(:topic_resource_key, "arn:aws:sns:us-west-2:123:test-topic")
        subscription.update_columns(resource_key: "pending:#{SecureRandom.uuid}", endpoint: "user@example.com")
        allow(SnsSubscriptionManager).to receive(:locate)
          .and_return(SnsSubscriptionManager::Response.new(error_message: "not confirmed yet"))
      end

      it "does not broadcast" do
        expect(Turbo::StreamsChannel).not_to receive(:broadcast_refresh_to)
        job.perform(subscription.id)
      end
    end

    context "when the subscription is already confirmed" do
      it "does not attempt to save or broadcast" do
        expect(Turbo::StreamsChannel).not_to receive(:broadcast_refresh_to)
        expect_any_instance_of(Subscription).not_to receive(:save) # rubocop:disable RSpec/AnyInstance
        job.perform(subscription.id)
      end
    end

    context "when the subscription does not exist" do
      it "returns without error" do
        expect { job.perform(-1) }.not_to raise_error
      end
    end
  end
end
