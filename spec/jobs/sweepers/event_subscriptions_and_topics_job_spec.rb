require "rails_helper"

RSpec.describe Sweepers::EventSubscriptionsAndTopicsJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { users(:admin_user) }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  let(:now) { Time.zone.parse("2026-05-01 12:00:00") }

  let(:event_old) { events(:hardrock_2014) }
  let(:event_recent) { events(:hardrock_2015) }

  before do
    travel_to(now)

    Subscription.delete_all
    Event.update_all(topic_resource_key: nil)

    allow(SnsClientFactory).to receive(:client).and_return(sns_client)
    sns_client.stub_responses(:delete_topic, {})

    allow(AdminMailer).to receive(:job_report).and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: true))
  end

  def make_subscription(event)
    Subscription.create!(
      user: user,
      subscribable: event,
      protocol: :email,
      endpoint: user.email,
      resource_key: "arn:aws:sns:us-west-2:123:subscription-#{SecureRandom.hex(4)}",
    )
  end

  describe "Pass 1 — sweep stale Event subscriptions" do
    it "destroys subscriptions for Events older than 3 months" do
      event_old.update_columns(scheduled_start_time: 4.months.ago)
      sub = make_subscription(event_old)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(false)
    end

    it "preserves subscriptions for Events younger than 3 months" do
      event_recent.update_columns(scheduled_start_time: 2.months.ago)
      sub = make_subscription(event_recent)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(true)
    end

    it "does not touch Effort subscriptions" do
      effort = efforts(:hardrock_2014_finished_first)
      effort_sub = Subscription.create!(
        user: user,
        subscribable: effort,
        protocol: :email,
        endpoint: user.email,
      )

      described_class.perform_now

      expect(Subscription.exists?(effort_sub.id)).to be(true)
    end
  end

  describe "Pass 2 — sweep topics on stale Events" do
    let(:topic_arn) { "arn:aws:sns:us-west-2:123:t-follow-stale-event-topic" }

    it "deletes the topic when stale and no subscribers" do
      event_old.update_columns(scheduled_start_time: 31.days.ago, topic_resource_key: topic_arn)

      allow(SnsTopicManager).to receive(:delete).and_return(topic_arn)

      described_class.perform_now

      expect(SnsTopicManager).to have_received(:delete).with(resource: event_old)
      expect(event_old.reload.topic_resource_key).to be_nil
    end

    it "preserves the topic when subscribers still exist" do
      event_recent.update_columns(scheduled_start_time: 31.days.ago, topic_resource_key: topic_arn)
      make_subscription(event_recent)

      expect(SnsTopicManager).not_to receive(:delete)

      described_class.perform_now

      expect(event_recent.reload.topic_resource_key).to eq(topic_arn)
    end

    it "preserves the topic for Events younger than 30 days" do
      event_recent.update_columns(scheduled_start_time: 20.days.ago, topic_resource_key: topic_arn)

      expect(SnsTopicManager).not_to receive(:delete)

      described_class.perform_now

      expect(event_recent.reload.topic_resource_key).to eq(topic_arn)
    end
  end

  describe "cross-pass interaction" do
    let(:topic_arn) { "arn:aws:sns:us-west-2:123:t-follow-cross-pass-event" }

    it "Pass 2 deletes the topic of an event whose subscriptions Pass 1 just removed" do
      event_old.update_columns(scheduled_start_time: 4.months.ago, topic_resource_key: topic_arn)
      make_subscription(event_old)

      allow(SnsTopicManager).to receive(:delete).and_return(topic_arn)

      described_class.perform_now

      expect(SnsTopicManager).to have_received(:delete).with(resource: event_old)
      expect(event_old.reload.topic_resource_key).to be_nil
      expect(Subscription.where(subscribable: event_old)).to be_empty
    end
  end

  describe "dry-run mode" do
    let(:topic_arn) { "arn:aws:sns:us-west-2:123:t-follow-dry-event" }

    it "performs no destruction and no AWS deletes" do
      event_old.update_columns(scheduled_start_time: 4.months.ago, topic_resource_key: topic_arn)
      sub = make_subscription(event_old)

      expect(SnsTopicManager).not_to receive(:delete)

      described_class.perform_now(dry_run: true)

      expect(Subscription.exists?(sub.id)).to be(true)
      expect(event_old.reload.topic_resource_key).to eq(topic_arn)
    end
  end

  describe "reporting" do
    it "sends a job report via AdminMailer" do
      mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow(AdminMailer).to receive(:job_report).and_return(mail)

      described_class.perform_now

      expect(AdminMailer).to have_received(:job_report).with(described_class, kind_of(String))
      expect(mail).to have_received(:deliver_now)
    end
  end
end
