require "rails_helper"

RSpec.describe Subscription, type: :model do
  subject(:subscription) { described_class.new(user: user, subscribable: subscribable, protocol: protocol, endpoint: endpoint) }

  let(:user) { users(:admin_user) }
  let(:subscribable) { people(:tuan_jacobs) }
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
    let(:subscribable_type) { "Person" }
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

  describe "welcome dispatch on create" do
    let(:user) { users(:admin_user) }
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

    context "when protocol is email" do
      it "enqueues the welcome mailer" do
        expect do
          described_class.create!(user: user, subscribable: effort, protocol: :email, endpoint: user.email)
        end.to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end

    context "when protocol is sms" do
      it "enqueues the SMS welcome job" do
        expect do
          described_class.create!(user: user, subscribable: effort, protocol: :sms, endpoint: "+13035551212")
        end.to have_enqueued_job(SmsSubscriptionWelcomeJob)
      end
    end

    context "when protocol is http" do
      it "does not enqueue any welcome job or mail" do
        expect do
          described_class.create!(user: user, subscribable: effort, protocol: :http, endpoint: "https://example.com/hook")
        end.not_to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end

    context "when an existing subscription is updated" do
      let!(:subscription) do
        described_class.create!(user: user, subscribable: effort, protocol: :email, endpoint: user.email)
      end

      it "does not re-fire the welcome (after_create_commit only)" do
        expect do
          subscription.update!(endpoint: "new-#{user.email}")
        end.not_to have_enqueued_mail(SubscriptionMailer, :welcome)
      end
    end
  end
end
