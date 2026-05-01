require "rails_helper"

RSpec.describe Users::SessionsController do
  describe "GET /users/sign_in" do
    context "with no reason param" do
      it "renders the login form without a contextual alert" do
        get new_user_session_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(I18n.t("subscriptions.toggle.sign_in_required"))
      end
    end

    context "with reason=subscribe" do
      it "renders a contextual alert explaining the user must sign in to subscribe" do
        get new_user_session_path(reason: "subscribe")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("subscriptions.toggle.sign_in_required"))
      end
    end

    context "with an unrecognized reason value" do
      it "ignores the param and renders no contextual alert" do
        get new_user_session_path(reason: "something-else")
        expect(response.body).not_to include(I18n.t("subscriptions.toggle.sign_in_required"))
      end
    end
  end

  describe "POST /users/sign_in (auto-subscribe after login)" do
    include Warden::Test::Helpers
    include ActiveJob::TestHelper

    let(:user) { users(:admin_user) }
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
    let(:effort_sgid) { effort.to_signed_global_id(for: "subscribe_after_signin").to_s }

    let(:credentials) { { user: { email: user.email, password: "password" } } }

    before { effort.update!(topic_resource_key: "arn:aws:sns:us-west-2:123:fake-topic") }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
      Warden.test_reset!
    end

    context "without subscribe intent" do
      it "signs in and renders the standard navbar replace stream" do
        post user_session_path, params: credentials
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("ost_navbar")
      end

      it "does not create any subscription" do
        expect { post user_session_path, params: credentials }.not_to change(Subscription, :count)
      end
    end

    context "with email subscribe intent" do
      let(:params) { credentials.merge(subscribe_to: effort_sgid, notification_protocol: "email") }

      it "creates an email subscription on the carried subscribable" do
        expect { post user_session_path, params: params }.to change { effort.subscriptions.where(user: user, protocol: :email).count }.by(1)
      end

      it "sets the success flash" do
        post user_session_path, params: params
        expect(flash[:success]).to include(effort.name)
      end

      it "responds with the navbar replace stream (no visit redirect)" do
        post user_session_path, params: params
        expect(response.body).to include("ost_navbar")
        expect(response.body).not_to include(%(action="visit"))
      end
    end

    context "with SMS subscribe intent and the user already opted in" do
      let(:params) { credentials.merge(subscribe_to: effort_sgid, notification_protocol: "sms") }

      # update_columns bypasses the User callback chain — `update!` would trigger
      # normalize_phone's in-place gsub! which makes phone_changed? return true
      # and then clear_sms_consent_on_phone_change wipes phone_confirmed_at.
      before { user.update_columns(phone: "+13035551212", phone_confirmed_at: 1.day.ago) }

      it "creates an SMS subscription on the carried subscribable" do
        expect { post user_session_path, params: params }.to change { effort.subscriptions.where(user: user, protocol: :sms).count }.by(1)
      end

      it "responds with the navbar replace stream (no visit redirect)" do
        post user_session_path, params: params
        expect(response.body).to include("ost_navbar")
        expect(response.body).not_to include(%(action="visit"))
      end
    end

    context "with SMS subscribe intent and the user NOT opted in" do
      let(:params) { credentials.merge(subscribe_to: effort_sgid, notification_protocol: "sms") }

      before { user.update!(phone: nil, phone_confirmed_at: nil) }

      it "does not create a subscription (will be created post-opt-in by the SMS settings flow)" do
        expect { post user_session_path, params: params }.not_to change(Subscription, :count)
      end

      it "responds with a visit stream pointing at the SMS settings page with the subscribable re-encoded for the downstream purpose" do
        post user_session_path, params: params
        expect(response.body).to include(%(action="visit"))

        # Extract the visit stream's href and assert it points at SMS settings.
        doc = Nokogiri::HTML.fragment(response.body)
        visit_node = doc.css("turbo-stream[action=visit]").first
        expect(visit_node).not_to be_nil
        visit_uri = URI.parse(visit_node["href"])
        expect(visit_uri.path).to eq(user_settings_sms_messaging_path)

        # The SGID handed off must decode for the SMS opt-in flow's purpose,
        # not the login flow's purpose. UserSettingsController#pending_subscribable
        # uses "sms_opt_in_subscribe"; if we forwarded the inbound SGID unchanged
        # (which was signed for "subscribe_after_signin"), it would fail to
        # locate downstream and the streamlined opt-in flow would dead-end.
        handoff_sgid = Rack::Utils.parse_nested_query(visit_uri.query)["subscribe_to"]
        expect(GlobalID::Locator.locate_signed(handoff_sgid, for: "sms_opt_in_subscribe")).to eq(effort)
      end
    end

    context "with a tampered or invalid signed GID" do
      let(:params) { credentials.merge(subscribe_to: "garbage", notification_protocol: "email") }

      it "signs the user in but does not create any subscription" do
        expect { post user_session_path, params: params }.not_to change(Subscription, :count)
        expect(response.body).to include("ost_navbar")
      end
    end

    context "with a signed GID issued for a different purpose" do
      let(:wrong_sgid) { effort.to_signed_global_id(for: "some_other_purpose").to_s }
      let(:params) { credentials.merge(subscribe_to: wrong_sgid, notification_protocol: "email") }

      it "signs the user in but does not create any subscription" do
        expect { post user_session_path, params: params }.not_to change(Subscription, :count)
      end
    end
  end
end
