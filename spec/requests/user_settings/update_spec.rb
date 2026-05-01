require "rails_helper"

RSpec.describe "UserSettings#update" do
  include ActiveJob::TestHelper
  include Warden::Test::Helpers

  subject(:make_request) { put user_settings_update_path, params: params, headers: { "HTTP_REFERER" => user_settings_sms_messaging_path } }

  let(:user) { users(:third_user) }

  before { login_as user, scope: :user }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
    Warden.test_reset!
  end

  context "when the user transitions from not-opted-in to opted-in" do
    let(:params) do
      {
        user: {
          phone: "303-555-1212",
          sms_consent: "1",
        },
      }
    end

    it "enqueues SmsOptInWelcomeJob with the user" do
      expect { make_request }.to have_enqueued_job(SmsOptInWelcomeJob).with(user)
    end

    it "sets the opted-in flash" do
      make_request
      expect(flash[:info]).to eq(I18n.t("sms.consent.opted_in"))
    end
  end

  context "when the user transitions from opted-in to opted-out" do
    before { user.update!(phone: "+13035551212", phone_confirmed_at: 5.days.ago) }

    let(:params) do
      {
        user: {
          phone: "303-555-1212",
          sms_consent: "0",
        },
      }
    end

    it "does not enqueue SmsOptInWelcomeJob" do
      expect { make_request }.not_to have_enqueued_job(SmsOptInWelcomeJob)
    end

    it "sets the opted-out flash" do
      make_request
      expect(flash[:info]).to eq(I18n.t("sms.consent.opted_out"))
    end
  end

  context "when the user updates an unrelated field with no SMS opt-in change" do
    let(:params) do
      {
        user: {
          first_name: "Renamed",
        },
      }
    end

    it "does not enqueue SmsOptInWelcomeJob" do
      expect { make_request }.not_to have_enqueued_job(SmsOptInWelcomeJob)
    end
  end

  context "when the user re-saves the form while already opted-in (no transition)" do
    before { user.update!(phone: "+13035551212", phone_confirmed_at: 5.days.ago) }

    let(:params) do
      {
        user: {
          phone: "303-555-1212",
          sms_consent: "1",
        },
      }
    end

    it "does not enqueue SmsOptInWelcomeJob" do
      expect { make_request }.not_to have_enqueued_job(SmsOptInWelcomeJob)
    end
  end

  context "when the opt-in transition carries a pending Effort subscribable" do
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
    let(:params) do
      {
        user: { phone: "303-555-1212", sms_consent: "1" },
        subscribe_to_type: "Effort",
        subscribe_to_id: effort.to_param,
      }
    end

    before { effort.update!(topic_resource_key: "arn:aws:sns:us-west-2:123:fake-effort-topic") }

    it "creates an SMS subscription on the pending subscribable" do
      expect { make_request }.to change { effort.subscriptions.where(user: user, protocol: :sms).count }.by(1)
    end

    it "redirects to the subscribable's show page rather than the referrer" do
      make_request
      expect(response).to redirect_to(polymorphic_path(effort))
    end

    it "sets both the opted-in flash and the subscription-success flash" do
      make_request
      expect(flash[:info]).to eq(I18n.t("sms.consent.opted_in"))
      expect(flash[:success]).to include(effort.name)
    end

    it "still enqueues SmsOptInWelcomeJob (the welcome SMS)" do
      expect { make_request }.to have_enqueued_job(SmsOptInWelcomeJob).with(user)
    end

    it "enqueues SmsSubscriptionWelcomeJob via the new Subscription's after_create_commit" do
      expect { make_request }.to have_enqueued_job(SmsSubscriptionWelcomeJob)
    end
  end

  context "when the opt-in transition carries a non-existent subscribable id" do
    let(:params) do
      {
        user: { phone: "303-555-1212", sms_consent: "1" },
        subscribe_to_type: "Effort",
        subscribe_to_id: "does-not-exist",
      }
    end

    it "still completes the opt-in without raising" do
      expect { make_request }.not_to raise_error
      expect(user.reload.sms_opted_in?).to be true
    end

    it "does not create any subscription" do
      expect { make_request }.not_to change(Subscription, :count)
    end

    it "redirects to the referrer" do
      make_request
      expect(response).to redirect_to(user_settings_sms_messaging_path)
    end
  end

  context "when the opt-in transition carries a disallowed subscribable type" do
    let(:params) do
      {
        user: { phone: "303-555-1212", sms_consent: "1" },
        subscribe_to_type: "User",
        subscribe_to_id: "1",
      }
    end

    it "ignores the subscribable params and completes the opt-in" do
      expect { make_request }.not_to change(Subscription, :count)
      expect(user.reload.sms_opted_in?).to be true
    end
  end

  context "when the user is already subscribed to the pending subscribable by SMS" do
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
    let(:params) do
      {
        user: { phone: "303-555-1212", sms_consent: "1" },
        subscribe_to_type: "Effort",
        subscribe_to_id: effort.to_param,
      }
    end

    before do
      effort.update!(topic_resource_key: "arn:aws:sns:us-west-2:123:fake-effort-topic")
      effort.subscriptions.create!(user: user, protocol: :sms, endpoint: "+13035551212", resource_key: "arn:aws:sns:us-west-2:123:fake-sub")
    end

    it "does not create a duplicate subscription" do
      expect { make_request }.not_to(change { effort.subscriptions.where(user: user, protocol: :sms).count })
    end

    it "still redirects to the subscribable" do
      make_request
      expect(response).to redirect_to(polymorphic_path(effort))
    end
  end
end
