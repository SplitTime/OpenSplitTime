require "rails_helper"

RSpec.describe "crew access board URL state", :js do
  let(:event_group) { event_groups(:sum) }
  let(:gle) { gating_location_events(:sum_bandera_gate_100k) }

  before { allow(Projection).to receive(:execute_query).and_return([]) }

  scenario "control changes land in the URL and a reload reproduces the view" do
    sign_in users(:admin_user)
    visit live_event_group_crew_access_board_path(event_group, gle)

    select "Bib number", from: "Sort by"
    expect(page).to have_current_path(/sort=bib/, url: true)

    fill_in "Find runner", with: "anvil"
    expect(page).to have_current_path(/search=anvil/, url: true)

    page.refresh
    expect(page).to have_select("Sort by", selected: "Bib number")
    expect(find_field("Find runner").value).to eq("anvil")
  end
end
