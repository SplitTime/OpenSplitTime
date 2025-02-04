require "rails_helper"

RSpec.describe "Create new connection", type: :system, js: true do
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:hardrock) }
  let(:event_group) { event_groups(:hardrock_2015) }

  let(:service) { Connectors::Service.find("runsignup") }
  let(:valid_runsignup_id) { 85675 }

  context "when credentials are missing" do
    scenario "owner attempts to create a connection with RunSignup" do
      login_as owner, scope: :user
      visit_page

      expect(page).to have_text("Connect to RunSignup")
      expect(page).to have_text("Credentials are missing")
    end

    scenario "steward attempts to create a connection with RunSignup" do
      login_as steward, scope: :user
      visit_page

      expect(page).to have_text("Connect to RunSignup")
      expect(page).to have_text("Credentials are missing")
    end
  end

  context "when credentials are present" do
    before do
      owner.credentials.create!(service_identifier: service.identifier, key: "api_key", value: "1234")
      owner.credentials.create!(service_identifier: service.identifier, key: "api_secret", value: "2345")
    end

    scenario "owner creates a connection with RunSignup" do
      login_as owner, scope: :user
      visit_page

      expect(page).to have_text("Connect to RunSignup")
      expect(page).not_to have_text("Credentials are missing")

      fill_in "connection[source_id]", with: valid_runsignup_id
      expect { click_button "Save" }.to change(Connection, :count).by(1)
      expect(page).to have_link("Remove")
    end

    context "when a connection already exists" do
      before do
        event_group.connections.create!(
          service_identifier: service.identifier,
          source_type: "Race",
          source_id: valid_runsignup_id,
          destination_type: "EventGroup",
          destination_id: event_group.id,
        )
      end

      scenario "owner deletes a connection" do
        login_as owner, scope: :user
        visit_page

        expect(page).to have_text("Connect to RunSignup")
        expect(page).to have_link("Remove")
        expect do
          click_link("Remove")
          expect(page).to have_button("Save", disabled: true)
        end.to change(Connection, :count).by(-1)
      end
    end
  end

  def visit_page
    visit event_group_connect_service_path(event_group, service)
  end
end
