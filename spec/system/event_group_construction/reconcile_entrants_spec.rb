require "rails_helper"

RSpec.describe "reconcile entrants from the reconcile view" do
  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event_group) { event_groups(:rufa_2016) }
  let(:organization) { event_group.organization }
  let(:entrant) { event_group.efforts.find_by(first_name: "Finished", last_name: "First") }

  scenario "Auto reconcile" do
    login_as steward, scope: :user
    visit_page

    click_button "Auto Reconcile"
    expect(page).to have_current_path(reconcile_event_group_path(event_group))
    expect(page).to have_content("Automatic reconcile has started")
  end

  scenario "Create a person" do
    login_as steward, scope: :user
    visit_page

    expect do
      within("##{dom_id(entrant, :reconcile_row)}") do
        click_button "New person"
        expect(page).to have_current_path(reconcile_event_group_path(event_group))
      end.to change { Person.count }.by(1).and change(entrant, :person_id).from(nil)
    end
  end

  scenario "Match a person" do
    login_as steward, scope: :user
    visit_page

    expect do
      within("##{dom_id(entrant, :reconcile_row)}") do
        click_button "Same person >>"
        expect(page).to have_current_path(reconcile_event_group_path(event_group))
      end.to change { entrant.reload.person_id }.from(nil)
    end
  end

  def visit_page
    visit reconcile_event_group_path(event_group)
  end
end
