require "rails_helper"

RSpec.describe "assign bibs in event group construction", js: true do
  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event) { events(:ramble) }
  let(:event_group) { event_groups(:ramble) }
  let(:organization) { event_group.organization }

  scenario "Manually assign bib numbers" do
    login_as steward, scope: :user
    visit_page

    fill_in "event_group_bib_for_#{event.efforts.first.id}", with: "1"
    fill_in "event_group_bib_for_#{event.efforts.second.id}", with: "3"
    fill_in "event_group_bib_for_#{event.efforts.third.id}", with: "5"
    fill_in "event_group_bib_for_#{event.efforts.last.id}", with: "7"

    expect do
      click_button("Update")
      expect(page).to have_current_path(entrants_event_group_path(event_group))
    end.to change { event.efforts.pluck(:bib_number) }.from([nil, nil, nil, nil]).to(array_including([1, 3, 5, 7]))
  end

  scenario "Automatically assign bib numbers Hardrock style" do
    login_as steward, scope: :user
    visit_page

    click_button "Auto Assign"

    expect do
      accept_confirm do
        click_link "Hardrock"
      end
      expect(page).to have_field("event_group_bib_for_#{event.efforts.find_by(last_name: "First").id}", with: "100")
    end.to change { event.efforts.pluck(:bib_number) }.from([nil, nil, nil, nil]).to(array_including([100, 101, 102, 103]))

  end

  def visit_page
    visit assign_bibs_event_group_path(event_group)
  end
end
