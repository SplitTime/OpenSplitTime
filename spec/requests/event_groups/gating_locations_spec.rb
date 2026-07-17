require "rails_helper"

RSpec.describe "EventGroups::GatingLocations" do
  include Warden::Test::Helpers

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }
  let(:gating_location) { gating_locations(:sum_bandera_gate) }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }
  let(:owner_user) { users(:fourth_user) }
  let(:steward_user) { users(:fifth_user) }

  after { Warden.test_reset! }

  describe "authorization" do
    subject(:make_request) { get organization_event_group_gating_locations_path(organization, event_group) }

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

  describe "as an authorized user" do
    before { login_as admin_user, scope: :user }

    describe "GET index" do
      it "lists the event group's gating locations" do
        get organization_event_group_gating_locations_path(organization, event_group)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bandera Gate")
        expect(response.body).to include("45 min buffer")
      end
    end

    describe "GET new" do
      it "renders a fieldset for each event in the group" do
        get new_organization_event_group_gating_location_path(organization, event_group)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(events(:sum_100k).guaranteed_short_name)
        expect(response.body).to include(events(:sum_55k).guaranteed_short_name)
      end
    end

    describe "POST create" do
      subject(:make_request) do
        post organization_event_group_gating_locations_path(organization, event_group), params: { gating_location: params }
      end

      context "with a name and a configuration for one event" do
        let(:params) do
          {
            name: "Engineer Gate",
            gating_location_events_attributes: {
              "0" => {
                event_id: events(:sum_100k).id,
                gating_aid_station_id: aid_stations(:aid_station_0017).id,
                target_aid_station_id: aid_stations(:aid_station_0019).id,
                default_travel_buffer: 45,
                update_release_times: "0",
              },
              "1" => {
                event_id: events(:sum_55k).id,
                gating_aid_station_id: "",
                target_aid_station_id: "",
              },
            },
          }
        end

        it "creates the gating location with a single gating location event" do
          expect { make_request }.to change(GatingLocation, :count).by(1).and change(GatingLocationEvent, :count).by(1)
          expect(response).to redirect_to(organization_event_group_gating_locations_path(organization, event_group))

          gating_location = GatingLocation.find_by(name: "Engineer Gate")
          expect(gating_location.events).to contain_exactly(events(:sum_100k))
          gating_location_event = gating_location.gating_location_events.first
          expect(gating_location_event.default_travel_buffer).to eq(45)
          # Permitted and applied: DB default is true, so the submitted "0" proves the param flows through.
          expect(gating_location_event.update_release_times).to be(false)
        end
      end

      context "with a travel buffer out of range" do
        let(:params) do
          {
            name: "Engineer Gate",
            gating_location_events_attributes: {
              "0" => {
                event_id: events(:sum_100k).id,
                gating_aid_station_id: aid_stations(:aid_station_0017).id,
                target_aid_station_id: aid_stations(:aid_station_0019).id,
                default_travel_buffer: 1201,
              },
            },
          }
        end

        it "does not create a gating location and renders an error" do
          expect { make_request }.not_to change(GatingLocation, :count)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("must be less than or equal to 1200")
        end
      end

      context "with no name" do
        let(:params) { { name: "" } }

        it "does not create a gating location and renders an error" do
          expect { make_request }.not_to change(GatingLocation, :count)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Name can&#39;t be blank")
        end
      end

      context "with aid stations out of order" do
        let(:params) do
          {
            name: "Engineer Gate",
            gating_location_events_attributes: {
              "0" => {
                event_id: events(:sum_100k).id,
                gating_aid_station_id: aid_stations(:aid_station_0019).id,
                target_aid_station_id: aid_stations(:aid_station_0017).id,
              },
            },
          }
        end

        it "does not create a gating location and renders an error" do
          expect { make_request }.not_to change(GatingLocation, :count)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("must be farther along the course than the gating aid station")
        end
      end
    end

    describe "PATCH update" do
      subject(:make_request) do
        patch organization_event_group_gating_location_path(organization, event_group, gating_location),
              params: { gating_location: params }
      end

      context "when renaming" do
        let(:params) { { name: "Bandera Mine Gate" } }

        it "updates the name" do
          make_request

          expect(response).to redirect_to(organization_event_group_gating_locations_path(organization, event_group))
          expect(gating_location.reload.name).to eq("Bandera Mine Gate")
        end
      end

      context "when both aid stations are cleared for a configured event" do
        let(:params) do
          {
            name: gating_location.name,
            gating_location_events_attributes: {
              "0" => {
                id: gating_location_events(:sum_bandera_gate_55k).id,
                event_id: events(:sum_55k).id,
                gating_aid_station_id: "",
                target_aid_station_id: "",
              },
            },
          }
        end

        it "destroys the gating location event" do
          expect { make_request }.to change(GatingLocationEvent, :count).by(-1)
          expect(gating_location.reload.events).to contain_exactly(events(:sum_100k))
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the gating location and its gating location events" do
        expect { delete organization_event_group_gating_location_path(organization, event_group, gating_location) }
          .to change(GatingLocation, :count).by(-1).and change(GatingLocationEvent, :count).by(-2)

        expect(response).to redirect_to(organization_event_group_gating_locations_path(organization, event_group))
      end
    end
  end
end
