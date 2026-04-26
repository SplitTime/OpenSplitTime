require "rails_helper"

RSpec.describe "EventGroups#drop_list" do
  include Warden::Test::Helpers

  subject(:make_request) { get drop_list_event_group_path(event_group) }

  let(:event_group) { event_groups(:hardrock_2015) }
  let(:organization) { event_group.organization }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }
  let(:owner_user) { users(:fourth_user) }
  let(:steward_user) { users(:fifth_user) }

  after { Warden.test_reset! }

  context "when the user is not signed in" do
    it "does not render the page" do
      make_request
      expect(response).not_to have_http_status(:ok)
    end
  end

  context "when the user is not authorized to edit the event group" do
    before { login_as other_user, scope: :user }

    it "does not render the page" do
      make_request
      expect(response).not_to have_http_status(:ok)
    end
  end

  context "when the user is an admin" do
    before { login_as admin_user, scope: :user }

    it "renders successfully" do
      make_request
      expect(response).to have_http_status(:ok)
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
