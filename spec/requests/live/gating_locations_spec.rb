require "rails_helper"

RSpec.describe "Live::GatingLocations" do
  include Warden::Test::Helpers

  let(:event_group) { event_groups(:sum) }
  let(:gating_location) { gating_locations(:sum_bandera_gate) }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }
  let(:owner_user) { users(:fourth_user) }
  let(:steward_user) { users(:fifth_user) }

  after { Warden.test_reset! }

  describe "GET index authorization" do
    subject(:make_request) { get live_event_group_gating_locations_path(event_group) }

    context "when the user is not signed in" do
      it "redirects" do
        make_request
        expect(response).not_to have_http_status(:ok)
      end
    end

    context "when the user is not authorized to edit the event group" do
      before { login_as other_user, scope: :user }

      it "is not successful" do
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
        event_group.organization.update!(created_by: owner_user.id)
        login_as owner_user, scope: :user
      end

      it "renders successfully" do
        make_request
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is a steward of the organization" do
      before do
        event_group.organization.stewards << steward_user
        login_as steward_user, scope: :user
      end

      it "renders successfully" do
        make_request
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "as an authorized user" do
    before { login_as admin_user, scope: :user }

    describe "GET index" do
      it "lists the event group's gating locations" do
        get live_event_group_gating_locations_path(event_group)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bandera Gate")
      end
    end

    describe "GET show" do
      before { allow(Projection).to receive(:execute_query).and_return([]) }

      it "renders the per-event controls (buffer, sort, find runner, hide filters)" do
        get live_event_group_gating_location_path(event_group, gating_location)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Buffer (min)")
        expect(response.body).to include("Sort by")
        expect(response.body).to include("Find runner")
        expect(response.body).to include("Hide departed")
        expect(response.body).to include("Hide passed")
      end

      it "accepts the sort and filter params without error" do
        get live_event_group_gating_location_path(event_group, gating_location),
            params: { gating_location_event_id: gating_location_events(:sum_bandera_gate_100k).id,
                      sort: "release", hide_departed: "1", hide_passed: "1", search: "999" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when live entry is not available for the event group" do
      before { event_group.update!(available_live: false) }

      it "redirects away from the index" do
        get live_event_group_gating_locations_path(event_group)

        expect(response).not_to have_http_status(:ok)
      end
    end
  end
end
