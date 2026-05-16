require "rails_helper"

RSpec.describe Sweepers::EffortSubscriptionsAndTopicsJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { users(:admin_user) }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  # The job uses Time.current; pin it so the cutoff math is deterministic.
  let(:now) { Time.zone.parse("2026-05-01 12:00:00") }

  # Three efforts whose row-level state we control inside each context. Picking
  # fixture efforts (rather than create()) per project convention.
  let(:effort_old_finished) { efforts(:hardrock_2014_finished_first) }
  let(:effort_recent_finished) { efforts(:hardrock_2014_finished_with_stop) }
  let(:effort_active_unfinished) { efforts(:hardrock_2014_progress_sherman) }

  before do
    travel_to(now)

    # Start from a clean canvas so global queries only see what each example sets up.
    Subscription.delete_all
    Effort.update_all(topic_resource_key: nil)
    Event.update_all(topic_resource_key: nil)

    allow(SnsClientFactory).to receive(:client).and_return(sns_client)
    sns_client.stub_responses(:list_topics, topics: [], next_token: nil)
    sns_client.stub_responses(:delete_topic, {})

    allow(AdminMailer).to receive(:job_report).and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: true))
  end

  def make_subscription(effort, protocol: :email)
    Subscription.create!(
      user: user,
      subscribable: effort,
      protocol: protocol,
      endpoint: protocol == :email ? user.email : "+13035551212",
      resource_key: "arn:aws:sns:us-west-2:123:subscription-#{SecureRandom.hex(4)}",
    )
  end

  describe "Pass 1 — sweep stale Effort subscriptions" do
    it "destroys subscriptions for finished Efforts older than 10 days" do
      effort_old_finished.update_columns(finished: true, scheduled_start_time: 11.days.ago)
      sub = make_subscription(effort_old_finished)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(false)
    end

    it "preserves subscriptions for finished Efforts younger than 10 days" do
      effort_recent_finished.update_columns(finished: true, scheduled_start_time: 9.days.ago)
      sub = make_subscription(effort_recent_finished)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(true)
    end

    it "destroys subscriptions for unfinished Efforts older than 3 months (safety belt)" do
      effort_active_unfinished.update_columns(finished: false, scheduled_start_time: 4.months.ago)
      sub = make_subscription(effort_active_unfinished)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(false)
    end

    it "preserves subscriptions for unfinished Efforts younger than 3 months" do
      effort_active_unfinished.update_columns(finished: false, scheduled_start_time: 2.months.ago)
      sub = make_subscription(effort_active_unfinished)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(true)
    end

    it "falls back to event scheduled_start_time when the effort has none" do
      effort_old_finished.update_columns(finished: true, scheduled_start_time: nil)
      effort_old_finished.event.update_columns(scheduled_start_time: 11.days.ago)
      sub = make_subscription(effort_old_finished)

      described_class.perform_now

      expect(Subscription.exists?(sub.id)).to be(false)
    end
  end

  describe "Pass 2 — sweep topics on stale finished Efforts" do
    let(:topic_arn) { "arn:aws:sns:us-west-2:123:t-follow-stale-topic" }

    it "deletes the topic and clears topic_resource_key when finished + stale + no subscribers" do
      effort_old_finished.update_columns(
        finished: true,
        scheduled_start_time: 31.days.ago,
        topic_resource_key: topic_arn,
      )

      allow(SnsTopicManager).to receive(:delete).and_return(topic_arn)

      described_class.perform_now

      expect(SnsTopicManager).to have_received(:delete).with(resource: effort_old_finished)
      expect(effort_old_finished.reload.topic_resource_key).to be_nil
    end

    it "preserves the topic when subscribers still exist (Pass 1 didn't sweep them)" do
      # Subscriber is fresh — Pass 1 won't sweep, so Pass 2 must skip.
      effort_recent_finished.update_columns(
        finished: true,
        scheduled_start_time: 9.days.ago,
        topic_resource_key: topic_arn,
      )
      make_subscription(effort_recent_finished)

      expect(SnsTopicManager).not_to receive(:delete)

      described_class.perform_now

      expect(effort_recent_finished.reload.topic_resource_key).to eq(topic_arn)
    end

    it "preserves the topic when the Effort is not finished and younger than 3 months" do
      effort_active_unfinished.update_columns(
        finished: false,
        scheduled_start_time: 31.days.ago,
        topic_resource_key: topic_arn,
      )

      expect(SnsTopicManager).not_to receive(:delete)

      described_class.perform_now

      expect(effort_active_unfinished.reload.topic_resource_key).to eq(topic_arn)
    end

    it "deletes the topic for unfinished Efforts older than 3 months (safety belt)" do
      effort_active_unfinished.update_columns(
        finished: false,
        scheduled_start_time: 4.months.ago,
        topic_resource_key: topic_arn,
      )

      allow(SnsTopicManager).to receive(:delete).and_return(topic_arn)

      described_class.perform_now

      expect(SnsTopicManager).to have_received(:delete).with(resource: effort_active_unfinished)
      expect(effort_active_unfinished.reload.topic_resource_key).to be_nil
    end

    it "preserves the topic for finished Efforts younger than 30 days" do
      effort_recent_finished.update_columns(
        finished: true,
        scheduled_start_time: 20.days.ago,
        topic_resource_key: topic_arn,
      )

      expect(SnsTopicManager).not_to receive(:delete)

      described_class.perform_now

      expect(effort_recent_finished.reload.topic_resource_key).to eq(topic_arn)
    end
  end

  describe "Pass 3 — sweep orphaned AWS topics" do
    let(:live_arn) { "arn:aws:sns:us-west-2:123:t-follow-live-effort" }
    let(:orphaned_arn) { "arn:aws:sns:us-west-2:123:t-follow-orphan" }
    let(:foreign_arn) { "arn:aws:sns:us-west-2:123:something-unrelated" }

    it "deletes topics that match the OST naming pattern but no live resource" do
      # Recent + unfinished so Pass 2 skips it; only Pass 3 should act, and only on the orphaned topic.
      effort_active_unfinished.update_columns(
        finished: false,
        scheduled_start_time: 1.day.ago,
        topic_resource_key: live_arn,
      )

      sns_client.stub_responses(
        :list_topics,
        topics: [{ topic_arn: live_arn }, { topic_arn: orphaned_arn }, { topic_arn: foreign_arn }],
        next_token: nil,
      )

      expect(sns_client).to receive(:delete_topic).with(topic_arn: orphaned_arn).and_call_original

      described_class.perform_now
    end

    it "does not delete topics outside the OST naming pattern" do
      sns_client.stub_responses(:list_topics, topics: [{ topic_arn: foreign_arn }], next_token: nil)

      expect(sns_client).not_to receive(:delete_topic)

      described_class.perform_now
    end

    it "treats Event topic_resource_keys as live too" do
      event = events(:hardrock_2014)
      event_arn = "arn:aws:sns:us-west-2:123:t-follow-live-event"

      event.update_column(:topic_resource_key, event_arn)

      sns_client.stub_responses(:list_topics, topics: [{ topic_arn: event_arn }], next_token: nil)

      expect(sns_client).not_to receive(:delete_topic)

      described_class.perform_now
    end

    it "paginates list_topics until next_token is nil" do
      page_1_arn = "arn:aws:sns:us-west-2:123:t-follow-page1-orphan"
      page_2_arn = "arn:aws:sns:us-west-2:123:t-follow-page2-orphan"

      sns_client.stub_responses(
        :list_topics,
        [
          { topics: [{ topic_arn: page_1_arn }], next_token: "page-2" },
          { topics: [{ topic_arn: page_2_arn }], next_token: nil },
        ],
      )

      expect(sns_client).to receive(:delete_topic).with(topic_arn: page_1_arn).and_call_original
      expect(sns_client).to receive(:delete_topic).with(topic_arn: page_2_arn).and_call_original

      described_class.perform_now
    end

    it "re-checks the DB for an ARN before deleting (concurrent-creation guard)" do
      sns_client.stub_responses(:list_topics, topics: [{ topic_arn: orphaned_arn }], next_token: nil)

      # Simulate a resource grabbing this ARN between list_topics and delete by
      # making the per-ARN re-check report it as live. Inject the stub via a
      # job instance so we can avoid allow_any_instance_of.
      job = described_class.new
      allow(job).to receive(:any_topic_resource_key_exists?).with(orphaned_arn).and_return(true)

      expect(sns_client).not_to receive(:delete_topic)

      job.perform
    end

    it "raises OrphanedTopicDriftError when orphaned count exceeds threshold" do
      stub_const("Sweepers::EffortSubscriptionsAndTopicsJob::ORPHANED_DRIFT_THRESHOLD", 2)

      orphaned = (1..5).map { |i| { topic_arn: "arn:aws:sns:us-west-2:123:t-follow-orphaned-#{i}" } }
      sns_client.stub_responses(:list_topics, topics: orphaned, next_token: nil)

      expect { described_class.perform_now }
        .to raise_error(Sweepers::EffortSubscriptionsAndTopicsJob::OrphanedTopicDriftError, /5 orphaned/)
    end
  end

  describe "cross-pass interaction" do
    let(:topic_arn) { "arn:aws:sns:us-west-2:123:t-follow-cross-pass" }

    it "Pass 2 deletes the topic of an effort whose subscriptions Pass 1 just removed" do
      effort_old_finished.update_columns(
        finished: true,
        scheduled_start_time: 35.days.ago,
        topic_resource_key: topic_arn,
      )
      make_subscription(effort_old_finished)

      allow(SnsTopicManager).to receive(:delete).and_return(topic_arn)

      described_class.perform_now

      expect(SnsTopicManager).to have_received(:delete).with(resource: effort_old_finished)
      expect(effort_old_finished.reload.topic_resource_key).to be_nil
      expect(Subscription.where(subscribable: effort_old_finished)).to be_empty
    end
  end

  describe "dry-run mode" do
    let(:topic_arn) { "arn:aws:sns:us-west-2:123:t-follow-dry-run" }
    let(:orphaned_arn) { "arn:aws:sns:us-west-2:123:t-follow-dry-orphan" }

    it "performs no destruction and no AWS deletes" do
      effort_old_finished.update_columns(finished: true, scheduled_start_time: 11.days.ago, topic_resource_key: topic_arn)
      sub = make_subscription(effort_old_finished)
      sns_client.stub_responses(:list_topics, topics: [{ topic_arn: orphaned_arn }], next_token: nil)

      expect(SnsTopicManager).not_to receive(:delete)
      expect(sns_client).not_to receive(:delete_topic)

      described_class.perform_now(dry_run: true)

      expect(Subscription.exists?(sub.id)).to be(true)
      expect(effort_old_finished.reload.topic_resource_key).to eq(topic_arn)
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
