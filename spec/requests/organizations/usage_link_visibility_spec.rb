require "rails_helper"

RSpec.describe "Organizations usage-report link visibility" do
  include Warden::Test::Helpers

  let(:hardrock) { organizations(:hardrock) }
  let(:admin_user) { users(:admin_user) }
  let(:non_admin_user) { users(:third_user) }

  after { Warden.test_reset! }

  describe "GET /organizations/:id" do
    it "shows the admin-only Usage report link when signed in as an admin" do
      login_as admin_user, scope: :user

      get organization_path(hardrock)

      expect(response.body).to include("Usage report")
      expect(response.body).to include(organization_usage_path(hardrock))
    end

    it "hides the Usage report link from non-admin users" do
      login_as non_admin_user, scope: :user

      get organization_path(hardrock)

      expect(response.body).not_to include("Usage report")
    end

    it "hides the Usage report link from visitors" do
      get organization_path(hardrock)

      expect(response.body).not_to include("Usage report")
    end
  end
end
