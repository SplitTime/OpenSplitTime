require "rails_helper"

RSpec.describe Subscription, type: :model do
  subject(:subscription) { described_class.new(user: user, subscribable: subscribable, protocol: protocol, endpoint: endpoint) }

  let(:user) { users(:admin_user) }
  let(:subscribable) { efforts(:rufa_2017_12h_not_started) }
  let(:protocol) { :email }
  let(:endpoint) { user&.email }

  context "when created with a user, a subscribable, a protocol, and an endpoint" do
    it "is valid" do
      expect(subscription).to be_valid
      expect { subscription.save }.to change(described_class, :count).by(1)
    end
  end

  context "when created without a user" do
    let(:user) { nil }

    it "is invalid" do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:user_id]).to include("can't be blank")
    end
  end

  context "when created without a subscribable" do
    let(:subscribable) { nil }

    it "is invalid" do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:subscribable_id]).to include("can't be blank")
    end
  end

  context "when created with ids instead of user and subscribable objects" do
    subject(:subscription) do
      described_class.new(
        user_id: user_id,
        subscribable_type: subscribable_type,
        subscribable_id: subscribable_id,
        protocol: protocol,
        endpoint: endpoint,
      )
    end

    let(:user_id) { user.id }
    let(:subscribable_type) { "Effort" }
    let(:subscribable_id) { subscribable.id }

    context "when all ids are valid" do
      it "is valid" do
        expect(subscription).to be_valid
      end
    end

    context "when the user_id is invalid" do
      let(:user_id) { 0 }

      it "is invalid" do
        expect(subscription).not_to be_valid
        expect(subscription.errors.full_messages).to include(/User can't be blank/)
      end
    end

    context "when the subscribable_id is invalid" do
      let(:subscribable_id) { 0 }

      it "is invalid" do
        expect(subscription).not_to be_valid
        expect(subscription.errors.full_messages).to include(/Subscribable can't be blank/)
      end
    end

    context "when the subscribable_type is nil" do
      let(:subscribable_type) { nil }

      it "is invalid" do
        expect(subscription).not_to be_valid
        expect(subscription.errors.full_messages).to include(/Subscribable can't be blank/)
      end
    end
  end

  describe "welcome dispatch" do
    let(:user) { users(:admin_user) }
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

    context "when an SMS subscription is created" do
      it "enqueues the SMS welcome job immediately" do
        expect do
          described_class.create!(user: user, subscribable: effort, protocol: :sms, endpoint: "+13035551212")
        end.to have_enqueued_job(SmsSubscriptionWelcomeJob)
      end
    end

    context "when an email subscription is created" do
      it "does not enqueue the welcome mailer on create — defers until AWS confirms" do
        expect do
          described_class.create!(user: user, subscribable: effort, protocol: :email, endpoint: user.email)
        end.not_to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end

    context "when an http subscription is created" do
      it "does not enqueue any welcome" do
        expect do
          described_class.create!(user: user, subscribable: effort, protocol: :http, endpoint: "https://example.com/hook")
        end.not_to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end

    context "when an email subscription transitions from pending to confirmed" do
      let(:subscription) do
        described_class.create!(user: user, subscribable: effort, protocol: :email, endpoint: user.email)
      end
      let(:confirmed_arn) { "arn:aws:sns:us-west-2:186555151487:topic:#{SecureRandom.uuid}" }

      before do
        subscription.update_column(:resource_key, "pending#{SecureRandom.uuid}")
        subscription.reload
      end

      it "enqueues the welcome mailer on the transition" do
        subscription.resource_key = confirmed_arn
        expect { subscription.save(validate: false) }.to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end

    context "when an already-confirmed email subscription is saved again" do
      let(:subscription) do
        described_class.create!(user: user, subscribable: effort, protocol: :email, endpoint: user.email)
      end
      let(:confirmed_arn) { "arn:aws:sns:us-west-2:186555151487:topic:#{SecureRandom.uuid}" }

      before do
        subscription.update_column(:resource_key, confirmed_arn)
        allow(SnsSubscriptionManager).to receive(:update).and_return(
          SnsSubscriptionManager::Response.new(subscription_arn: confirmed_arn),
        )
      end

      it "does not re-fire the welcome mailer (no resource_key transition)" do
        expect do
          subscription.update!(endpoint: "new-#{user.email}")
        end.not_to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end
  end
end
