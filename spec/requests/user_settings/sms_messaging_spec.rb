require "rails_helper"

RSpec.describe "GET /user_settings/sms_messaging" do
  include Warden::Test::Helpers

  subject(:make_request) { get user_settings_sms_messaging_path, params: query_params }

  let(:user) { users(:third_user) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

  before do
    effort.update!(topic_resource_key: "arn:aws:sns:us-west-2:123:fake-effort-topic")
    login_as user, scope: :user
  end

  after { Warden.test_reset! }

  context "with no pending subscribable params" do
    let(:query_params) { {} }

    it "does not set a warning flash" do
      make_request
      expect(flash[:warning]).to be_nil
    end
  end

  context "with a pending subscribable for a user who has no phone" do
    let(:query_params) { { subscribe_to: effort.to_signed_global_id(for: "sms_opt_in_subscribe").to_s } }

    before { user.update!(phone: nil, phone_confirmed_at: nil) }

    it "sets a warning flash asking for phone and consent" do
      make_request
      expect(flash[:warning]).to eq(I18n.t("sms.consent.subscribe_pending_phone_and_consent", name: effort.name))
    end
  end

  context "with a pending subscribable for a user who has a phone but is not opted in" do
    let(:query_params) { { subscribe_to: effort.to_signed_global_id(for: "sms_opt_in_subscribe").to_s } }

    before { user.update!(phone: "+13035551212", phone_confirmed_at: nil) }

    it "sets a warning flash asking only for consent" do
      make_request
      expect(flash[:warning]).to eq(I18n.t("sms.consent.subscribe_pending_consent_only", name: effort.name))
    end
  end

  context "with a pending subscribable for a user who is already opted in" do
    let(:query_params) { { subscribe_to: effort.to_signed_global_id(for: "sms_opt_in_subscribe").to_s } }

    before { user.update!(phone: "+13035551212", phone_confirmed_at: 1.day.ago) }

    it "does not set a warning flash" do
      make_request
      expect(flash[:warning]).to be_nil
    end
  end

  context "with a tampered or invalid signed GID" do
    let(:query_params) { { subscribe_to: "obviously-not-a-real-signed-gid" } }

    before { user.update!(phone: nil, phone_confirmed_at: nil) }

    it "ignores the param and does not set a warning flash" do
      make_request
      expect(flash[:warning]).to be_nil
    end
  end

  context "with a signed GID issued for a different purpose" do
    let(:query_params) { { subscribe_to: effort.to_signed_global_id(for: "some_other_purpose").to_s } }

    before { user.update!(phone: nil, phone_confirmed_at: nil) }

    it "rejects the param and does not set a warning flash" do
      make_request
      expect(flash[:warning]).to be_nil
    end
  end
end
