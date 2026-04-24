require "rails_helper"

RSpec.describe "EventGroups#drop_list" do
  include Warden::Test::Helpers

  subject(:make_request) { get drop_list_event_group_path(event_group) }

  let(:event_group) { event_groups(:hardrock_2015) }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }

  after { Warden.test_reset! }

  context "when the user is not signed in" do
    it "redirects to sign in" do
      make_request
      expect(response).to redirect_to(new_user_session_path)
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
end
