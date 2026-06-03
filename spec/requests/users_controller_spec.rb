require "rails_helper"

RSpec.describe "UsersController" do
  include Warden::Test::Helpers

  let(:non_admin_user) { users(:third_user) }

  after { Warden.test_reset! }

  describe "GET /users" do
    context "when signed in as a non-admin" do
      before { login_as non_admin_user, scope: :user }

      it "redirects to root with an access-denied alert" do
        get users_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end

      it "redirects back to a same-host referrer" do
        get users_path, headers: { "HTTP_REFERER" => "http://www.example.com/organizations" }

        expect(response).to redirect_to("http://www.example.com/organizations")
        expect(flash[:alert]).to eq("Access denied.")
      end

      it "falls back to root rather than raising on an external referrer" do
        get users_path, headers: { "HTTP_REFERER" => "https://accounts.google.com/" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end
end
