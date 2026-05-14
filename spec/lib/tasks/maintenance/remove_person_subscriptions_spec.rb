require "rails_helper"
require "rake"

RSpec.describe "maintenance:remove_person_subscriptions", type: :task do
  let(:task_name) { "maintenance:remove_person_subscriptions" }
  let(:person) { people(:bruno_fadel) }
  let(:other_person) { people(:progress_cascade) }
  let(:admin) { users(:admin_user) }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == task_name }
    Rake::Task[task_name].reenable

    # Stub AWS so the test doesn't reach for the network.
    allow(SnsTopicManager).to receive(:delete)
    allow(SnsSubscriptionManager).to receive(:delete)
  end

  def silent_invoke
    capture_stdout { Rake::Task[task_name].invoke }
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def build_person_subscription(target_person, resource_key: "arn:aws:sns:us-west-2:123:fake-subscription-arn")
    Subscription.new(
      user: admin,
      subscribable: target_person,
      protocol: :email,
      endpoint: admin.email,
      resource_key: resource_key,
    ).tap { |sub| sub.save(validate: false) }
  end

  context "with Person topic resources and subscriptions present" do
    before do
      build_person_subscription(person)
      build_person_subscription(other_person)
    end

    it "deletes all Person-typed subscriptions and nils out the topic_resource_key on every person" do
      expect { silent_invoke }
        .to change { Subscription.where(subscribable_type: "Person").count }.to(0)
        .and change { Person.where.not(topic_resource_key: nil).count }.to(0)
    end

    it "calls SnsTopicManager.delete with each person that had a topic_resource_key" do
      affected_count = Person.where.not(topic_resource_key: nil).count
      expect(affected_count).to be > 0 # fixture sanity check

      silent_invoke

      expect(SnsTopicManager).to have_received(:delete).with(resource: person)
      expect(SnsTopicManager).to have_received(:delete).with(resource: other_person)
      expect(SnsTopicManager).to have_received(:delete).exactly(affected_count).times
    end

    it "skips per-subscription SnsSubscriptionManager.delete (topic deletion auto-prunes ARNs server-side)" do
      silent_invoke

      expect(SnsSubscriptionManager).not_to have_received(:delete)
    end

    it "leaves Effort subscriptions alone" do
      effort_count_before = Subscription.where(subscribable_type: "Effort").count
      expect(effort_count_before).to be > 0

      silent_invoke

      expect(Subscription.where(subscribable_type: "Effort").count).to eq(effort_count_before)
    end

    it "reports the counts in the summary output" do
      affected_count = Person.where.not(topic_resource_key: nil).count

      output = silent_invoke

      expect(output).to include("deleted 2 Person subscriptions")
      expect(output).to include("tore down #{affected_count} SNS topics")
    end

    it "is idempotent — a second run reports zero work" do
      silent_invoke
      Rake::Task[task_name].reenable

      output = silent_invoke

      expect(output).to include("deleted 0 Person subscriptions")
      expect(output).to include("tore down 0 SNS topics")
    end
  end

  context "when there is no Person-typed data left" do
    before do
      Person.where.not(topic_resource_key: nil).update_all(topic_resource_key: nil)
      Subscription.where(subscribable_type: "Person").delete_all
    end

    it "runs cleanly and reports zeros" do
      output = silent_invoke

      expect(output).to include("deleted 0 Person subscriptions")
      expect(output).to include("tore down 0 SNS topics")
    end
  end
end
