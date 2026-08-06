require "rails_helper"

RSpec.describe "Live::CrewAccessBoards" do
  include Warden::Test::Helpers

  let(:event_group) { event_groups(:sum) }
  let(:gle_100k) { gating_location_events(:sum_bandera_gate_100k) }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }
  let(:owner_user) { users(:fourth_user) }
  let(:steward_user) { users(:fifth_user) }

  after { Warden.test_reset! }

  before { allow(Projection).to receive(:execute_query).and_return([]) }

  describe "GET show authorization" do
    subject(:make_request) { get live_event_group_crew_access_board_path(event_group, gle_100k) }

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

    describe "GET show" do
      it "renders the board controls (buffer, sort, find runner, hide filters)" do
        get live_event_group_crew_access_board_path(event_group, gle_100k)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Buffer (min)")
        expect(response.body).to include("Sort by")
        expect(response.body).to include("Find runner")
        expect(response.body).to include("Hide departed")
        expect(response.body).to include("Hide passed")
      end

      it "subscribes to the crew access refresh stream and opts into morph refreshes" do
        get live_event_group_crew_access_board_path(event_group, gle_100k)

        expect(response.body).to include("turbo-cable-stream-source")
        expect(response.body).to include(%(name="turbo-refresh-method" content="morph"))
        expect(response.body).to include(%(name="turbo-refresh-scroll" content="preserve"))
      end

      describe "release rendering" do
        # sum_55k_progress_rolling sits between the 55k gate and target, so it gets a projected release
        let(:gle_55k) { gating_location_events(:sum_bandera_gate_55k) }

        it "renders a pending release with the flip controller and its epoch" do
          allow(Projection).to receive(:execute_query)
            .and_return([instance_double(Projection, low_seconds: 20.years.to_i)])

          get live_event_group_crew_access_board_path(event_group, gle_55k)

          expect(response.body).to include(%(data-controller="release-flip"))
          expect(response.body).to match(/data-release-flip-epoch-value="\d+"/)
        end

        it "renders a released row as the badge, without the flip controller" do
          allow(Projection).to receive(:execute_query)
            .and_return([instance_double(Projection, low_seconds: 3600)])

          get live_event_group_crew_access_board_path(event_group, gle_55k)

          expect(response.body).to include(">Now<")
          expect(response.body).not_to include("release-flip")
        end
      end

      it "accepts the control params without error" do
        get live_event_group_crew_access_board_path(event_group, gle_100k),
            params: { buffer: "90", sort: "release", hide_departed: "1", hide_passed: "1", search: "999" }

        expect(response).to have_http_status(:ok)
      end

      it "is not found for a gated event belonging to another event group" do
        expect { get live_event_group_crew_access_board_path(event_groups(:hardrock_2015), gle_100k) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when live entry is not available for the event group" do
      before { event_group.update!(available_live: false) }

      it "redirects away from the board" do
        get live_event_group_crew_access_board_path(event_group, gle_100k)

        expect(response).not_to have_http_status(:ok)
      end
    end
  end
end
