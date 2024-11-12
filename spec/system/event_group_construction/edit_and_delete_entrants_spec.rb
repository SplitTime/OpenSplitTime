# frozen_string_literal: true

require "rails_helper"

RSpec.describe "edit and delete entrants from the event group entrants view", js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event_group) { event_groups(:rufa_2016) }
  let(:organization) { event_group.organization }
  let(:entrant) { event_group.efforts.find_by(first_name: "Finished", last_name: "First") }

  scenario "Edit an entrant" do
    login_as steward, scope: :user
    visit_page

    within("##{dom_id(entrant, :event_group_setup)}") do
      button = page.find("button.dropdown-toggle")
      button.click
      click_link "Edit"
    end

    expect(page).to have_content("Edit Entrant - #{entrant.full_name}")
    fill_in "effort_last_name", with: "New Last Name", fill_options: { clear: :backspace }
    expect do
      click_button "Update Entrant"
      # Wait for the update to complete
      expect(page).to have_css(".bg-highlight")
    end.to change { entrant.reload.last_name }.from("First").to("New Last Name")

    expect(page).to have_content(entrant.reload.full_name)
  end

  scenario "Edit an entrant with failed attempt" do
    login_as steward, scope: :user
    visit_page

    within("##{dom_id(entrant, :event_group_setup)}") do
      button = page.find("button.dropdown-toggle")
      button.click
      click_link "Edit"
    end

    expect(page).to have_content("Edit Entrant - #{entrant.full_name}")
    fill_in "effort_last_name", with: "New Last Name", fill_options: { clear: :backspace }
    fill_in "effort_birthdate", with: "1/1/3000", fill_options: { clear: :backspace }
    click_button "Update Entrant"
    # Wait for the update to complete
    sleep 0.5
    expect(page).to have_content("Birthdate can't be today or in the future")

    fill_in "effort_birthdate", with: "1/1/2000", fill_options: { clear: :backspace }

    expect do
      click_button "Update Entrant"
      # Wait for the update to complete
      expect(page).to have_css(".bg-highlight")
    end.to change { entrant.reload.last_name }.from("First").to("New Last Name")
             .and change { entrant.reload.birthdate }.to("2000-01-01".to_date)

    expect(page).to have_content(entrant.reload.full_name)
  end

  scenario "Delete an entrant" do
    login_as steward, scope: :user
    visit_page

    perform_enqueued_jobs do
      expect do
        within("##{dom_id(entrant, :event_group_setup)}") do
          button = page.find("button.dropdown-toggle")
          button.click
          click_link "Delete"
          accept_confirm
        end

        expect(page).not_to have_content(entrant.full_name)
      end.to change { event_group.efforts.count }.by(-1)
    end
  end

  def visit_page
    visit entrants_event_group_path(event_group)
  end
end
