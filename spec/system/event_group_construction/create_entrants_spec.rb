require "rails_helper"

RSpec.describe "create an entrant from the event group entrants view", :js do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:steward) { users(:fifth_user) }
  let(:event_group) { event_groups(:rufa_2016) }
  let(:organization) { event_group.organization }
  let(:entrant) { event_group.efforts.find_by(first_name: "Finished", last_name: "First") }

  before { organization.stewards << steward }

  scenario "Create an entrant" do
    login_as steward, scope: :user
    visit_page

    click_link "Add"
    expect(page).to have_content("Add an Entrant")

    fill_in "effort_first_name", with: "Fred"
    fill_in "effort_last_name", with: "Flintstone"
    select "Male", from: "effort_gender"

    expect do
      click_button "Create Entrant"
      # Wait for the update to complete
      expect(page).to have_css(".bg-highlight")
    end.to change { event_group.efforts.count }.by(1)

    expect(page).to have_content(entrant.reload.full_name)
  end

  scenario "Create the first entrant" do
    login_as steward, scope: :user
    event_group.events.flat_map(&:efforts).each(&:destroy)
    visit_page

    expect(page).to have_content("Add or Import Your Entrants")

    click_link "Add"
    expect(page).to have_content("Add an Entrant")

    fill_in "effort_first_name", with: "Barney"
    fill_in "effort_last_name", with: "Rubble"
    select "Male", from: "effort_gender"

    expect do
      click_button "Create Entrant"
      expect(page).to have_css(".bg-highlight")
    end.to change { event_group.reload.efforts.count }.by(1)

    expect(page).to have_content("Barney Rubble")
    expect(page).not_to have_content("Add or Import Your Entrants")
  end

  def visit_page
    visit entrants_event_group_path(event_group)
  end
end
