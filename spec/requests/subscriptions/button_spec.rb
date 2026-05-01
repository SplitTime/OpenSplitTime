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
    it "renders a sign-in prompt button inside the turbo-frame" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="#{dom_id(effort, :email)}"))
      expect(response.body).to include("You must be signed in")
    end

    it "renders the sign-in CTA with data-turbo-frame=_top so the click breaks out of the lazy frame" do
      get effort_subscription_button_path(effort, notification_protocol: "email")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<button[^>]*data-turbo-frame=["']_top["']/)
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
