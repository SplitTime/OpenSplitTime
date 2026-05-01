require "rails_helper"

RSpec.describe "GET /users/sign_in" do
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
