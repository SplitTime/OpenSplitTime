require "rails_helper"

RSpec.describe "GET subscription_button" do
  include Warden::Test::Helpers
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:effort) { efforts(:rufa_2017_12h_not_started) }
  let(:person) { people(:progress_cascade) }

  before do
    effort.update!(topic_resource_key: "arn:aws:sns:us-west-2:123:fake-effort-topic")
    person.update!(topic_resource_key: "arn:aws:sns:us-west-2:123:fake-person-topic")
  end

  after { Warden.test_reset! }

  context "when not signed in" do
    it "renders a sign-in CTA inside the turbo-frame" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="#{dom_id(effort, :email)}"))
    end

    it "renders the sign-in CTA as a link to new_user_session_path that loads into the form_modal turbo-frame and carries the subscribe intent" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML.fragment(response.body)
      link = doc.css(%(##{dom_id(effort, :email)} a)).first
      expect(link).not_to be_nil

      uri = URI.parse(link["href"])
      query = Rack::Utils.parse_nested_query(uri.query)
      expect(uri.path).to eq(new_user_session_path)
      expect(query["reason"]).to eq("subscribe")
      expect(query["notification_protocol"]).to eq("email")
      expect(query["subscribe_to"]).to be_present

      expect(link["data-turbo-frame"]).to eq("form_modal")
    end

    it "encodes the subscribable as a signed Global ID with the subscribe_after_signin purpose" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      doc = Nokogiri::HTML.fragment(response.body)
      link = doc.css(%(##{dom_id(effort, :email)} a)).first
      query = Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)

      located = GlobalID::Locator.locate_signed(query["subscribe_to"], for: "subscribe_after_signin")
      expect(located).to eq(effort)
    end
  end

  context "when signed in" do
    before { login_as user, scope: :user }

    it "renders the email subscription button for an effort inside a turbo-frame" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="#{dom_id(effort, :email)}"))
      expect(response.body).to include("turbo-frame")
      expect(response.body).to include("email")
    end

    it "renders the subscribe button with data-turbo-frame=_top so the form submission breaks out of the lazy frame" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<button[^>]*data-turbo-frame=["']_top["']/)
    end

    it "renders the email subscription button for a person inside a turbo-frame" do
      get person_subscription_button_path(person, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="#{dom_id(person, :email)}"))
      expect(response.body).to include("turbo-frame")
    end

    it "rejects an unknown protocol via routing constraints" do
      expect { get "/efforts/#{effort.id}/subscription_button/bogus" }
        .to raise_error(ActionController::RoutingError)
    end
  end

  context "when signed in as admin without SMS opted in" do
    let(:admin) { users(:admin_user) }

    before do
      admin.update!(phone: nil, phone_confirmed_at: nil)
      login_as admin, scope: :user
    end

    it "renders the SMS opt-in link with data-turbo-frame=_top so it breaks out of the lazy frame" do
      get effort_subscription_button_path(effort, notification_protocol: "sms")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user_settings_sms_messaging_path)
      expect(response.body).to match(/data-turbo-frame=["']_top["']/)
    end
  end
end
