require "rails_helper"

RSpec.describe "reconcile entrants from the reconcile view", js: true do
  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event_group) { event_groups(:rufa_2016) }
  let(:organization) { event_group.organization }

  scenario "Take event group public" do
    event_group.update(concealed: true)

    login_as steward, scope: :user
    visit_page

    expect do
      click_button "Go Public"
      page.accept_alert
      expect(page).to have_button("Take Private")
    end.to change { event_group.reload.concealed }.from(true).to(false)
  end

  scenario "Take event group private" do
    event_group.update(concealed: false)

    login_as steward, scope: :user
    visit_page

    expect do
      click_button "Take Private"
      page.accept_alert
      expect(page).to have_button("Go Public")
    end.to change { event_group.reload.concealed }.from(false).to(true)
  end

  scenario "Enable live entry" do
    event_group.update(available_live: false)

    login_as steward, scope: :user
    visit_page

    expect do
      click_button "Enable Live Entry"
      page.accept_alert
      expect(page).to have_button("Disable Live Entry")
    end.to change { event_group.reload.available_live }.from(false).to(true)
  end

  scenario "Disable live entry" do
    event_group.update(available_live: true)

    login_as steward, scope: :user
    visit_page

    expect do
      click_button "Disable Live Entry"
      page.accept_alert
      expect(page).to have_button("Enable Live Entry")
    end.to change { event_group.reload.available_live }.from(true).to(false)
  end

  def visit_page
    visit setup_summary_event_group_path(event_group)
  end
end
