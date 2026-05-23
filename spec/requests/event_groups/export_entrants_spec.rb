require "rails_helper"
require "csv"

RSpec.describe "EventGroups#export_entrants" do
  include Warden::Test::Helpers

  subject(:make_request) { get export_entrants_event_group_path(event_group, format: :csv) }

  let(:event_group) { event_groups(:hardrock_2015) }
  let(:organization) { event_group.organization }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }
  let(:owner_user) { users(:fourth_user) }
  let(:steward_user) { users(:fifth_user) }

  after { Warden.test_reset! }

  context "when the user is not signed in" do
    it "does not return CSV" do
      make_request
      expect(response).not_to have_http_status(:ok)
    end
  end

  context "when the user is not authorized to edit the event group" do
    before { login_as other_user, scope: :user }

    it "does not return CSV" do
      make_request
      expect(response).not_to have_http_status(:ok)
    end
  end

  context "when the user is an admin" do
    before { login_as admin_user, scope: :user }

    it "returns CSV scoped to this event group's entrants" do
      make_request

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to start_with("text/csv")
      expect(response.headers["Content-Disposition"]).to include("hardrock-2015-entrants-")

      table = ::CSV.parse(response.body, headers: true)
      expect(table.headers).to include("First name", "Last name", "Bib number", "Email", "Phone")
      expect(table.count).to eq(event_group.efforts.count)
      expect(table["Last name"]).to include("Jacobs") # hardrock_2015_tuan_jacobs fixture
    end
  end

  context "when the user owns the organization" do
    before do
      organization.update!(created_by: owner_user.id)
      login_as owner_user, scope: :user
    end

    it "renders successfully" do
      make_request
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is a steward of the organization" do
    before do
      organization.stewards << steward_user
      login_as steward_user, scope: :user
    end

    it "renders successfully" do
      make_request
      expect(response).to have_http_status(:ok)
    end
  end
end
