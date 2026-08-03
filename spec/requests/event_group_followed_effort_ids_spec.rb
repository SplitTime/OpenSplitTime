require "rails_helper"

RSpec.describe "EventGroupsController#followed_effort_ids" do
  include Warden::Test::Helpers

  let(:subscribed_user) { users(:admin_user) }
  let(:unsubscribed_user) { users(:third_user) }
  let(:event_group) { event_groups(:rufa_2017) }
  let(:followed_effort) { efforts(:rufa_2017_12h_not_started) }

  after { Warden.test_reset! }

  describe "GET /event_groups/:id/followed_effort_ids" do
    context "when not signed in" do
      it "redirects away" do
        get followed_effort_ids_event_group_path(event_group)

        expect(response).to have_http_status(:redirect)
        expect(response.location).not_to include("followed_effort_ids")
      end
    end

    context "when the user follows an effort in the event group" do
      before { login_as subscribed_user, scope: :user }

      it "returns the effort id once, although the user has multiple subscriptions to it" do
        expect(subscribed_user.subscriptions.where(subscribable: followed_effort).count).to be > 1

        get followed_effort_ids_event_group_path(event_group)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "effort_ids" => [followed_effort.id] })
      end
    end

    context "when the user's followed efforts are all in other event groups" do
      before { login_as subscribed_user, scope: :user }

      it "returns an empty array" do
        get followed_effort_ids_event_group_path(event_groups(:hardrock_2015))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "effort_ids" => [] })
      end
    end

    context "when the user follows no efforts" do
      before { login_as unsubscribed_user, scope: :user }

      it "returns an empty array" do
        get followed_effort_ids_event_group_path(event_group)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "effort_ids" => [] })
      end
    end
  end
end
