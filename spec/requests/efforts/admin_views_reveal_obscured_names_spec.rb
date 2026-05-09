require "rails_helper"

RSpec.describe "Efforts admin views reveal obscured names" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:effort) { efforts(:hardrock_2014_finished_first) }

  before do
    effort.update!(first_name: "Real", last_name: "Person")
    effort.person.update!(first_name: "Real", last_name: "Person", obscure_name: true, hide_age: true)
    login_as admin_user, scope: :user
  end

  after { Warden.test_reset! }

  describe "GET /efforts/:id/edit" do
    it "renders the real name in the page title and breadcrumbs" do
      get edit_effort_path(effort.reload)

      expect(response.body).to include("Real Person")
    end
  end

  describe "GET /efforts/:id/audit" do
    it "renders the real name" do
      get audit_effort_path(effort.reload)

      expect(response.body).to include("Real Person")
    end
  end

  describe "GET /efforts/:id/edit_split_times" do
    it "renders the real name" do
      get edit_split_times_effort_path(effort.reload)

      expect(response.body).to include("Real Person")
    end
  end
end
