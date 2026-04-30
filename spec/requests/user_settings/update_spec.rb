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
end
