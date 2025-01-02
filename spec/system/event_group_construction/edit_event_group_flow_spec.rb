require "rails_helper"

RSpec.describe "visit the edit event group page and make changes", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }

  scenario "The user is a visitor" do
    visit edit_organization_event_group_path(organization, event_group)

    expect(page).to have_current_path(root_path)
    verify_alert("You need to sign in or sign up before continuing")
  end

  scenario "The user is a user that is not authorized to edit the event group" do
    login_as user, scope: :user

    visit edit_organization_event_group_path(organization, event_group)

    expect(page).to have_current_path(root_path)
    verify_alert("Access denied")
  end

  scenario "The user is a steward of the organization" do
    login_as steward, scope: :user

    visit edit_organization_event_group_path(organization, event_group)
    verify_visit_and_update

    visit edit_organization_event_group_path(organization, event_group)
    expect(page).not_to have_link("Delete this event group")
    expect(page).not_to have_link("Delete all time records")
  end

  scenario "The user is the owner of the organization" do
    login_as owner, scope: :user

    visit edit_organization_event_group_path(organization, event_group)
    verify_visit_and_update

    visit edit_organization_event_group_path(organization, event_group)
    verify_confirm_and_delete_times

    visit edit_organization_event_group_path(organization, event_group)
    verify_confirm_and_delete
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user

    visit edit_organization_event_group_path(organization, event_group)
    verify_visit_and_update

    visit edit_organization_event_group_path(organization, event_group)
    verify_confirm_and_delete_times

    visit edit_organization_event_group_path(organization, event_group)
    verify_confirm_and_delete
  end

  def verify_visit_and_update
    expect(page).to have_current_path(edit_organization_event_group_path(organization, event_group))
    expect(event_group.name).to eq("SUM")

    fill_in "event_group_name", with: "Silverton Ultra Marathon"
    click_button "Continue"

    expect(page).not_to have_current_path(edit_organization_event_group_path(organization, event_group))

    event_group.reload
    expect(page).to have_current_path(setup_event_group_path(event_group))
    expect(event_group.name).to eq("Silverton Ultra Marathon")
  end

  def verify_confirm_and_delete_times
    click_link "Delete all time records"
    modal = page.find(:css, "#form_modal")
    expect(modal).to have_content("Are you absolutely sure?")
    expect(modal).to have_button("Permanently Delete", class: "disabled")

    fill_in "confirm", with: "#{event_group.name.upcase} TIMES"
    expect(modal).not_to have_button("Permanently Delete", class: "disabled")
    expect(modal).to have_button("Permanently Delete")

    split_time_count = event_group.split_times.count
    raw_time_count = event_group.raw_times.count

    expect do
      click_button "Permanently Delete"
      expect(page).not_to have_current_path(edit_organization_event_group_path(organization, event_group))
    end.to change { SplitTime.count }.by(-split_time_count).and change { RawTime.count }.by (-raw_time_count)

    expect(page).to have_current_path(setup_event_group_path(event_group))
  end

  def verify_confirm_and_delete
    click_link "Delete this event group"
    modal = page.find(:css, "#form_modal")
    expect(modal).to have_content("Are you absolutely sure?")
    expect(modal).to have_button("Permanently Delete", class: "disabled")

    fill_in "confirm", with: event_group.name.upcase
    expect(modal).not_to have_button("Permanently Delete", class: "disabled")
    expect(modal).to have_button("Permanently Delete")

    expect do
      click_button "Permanently Delete"
      expect(page).not_to have_current_path(edit_organization_event_group_path(organization, event_group))
    end.to change { EventGroup.count }.by(-1)
    expect(page).to have_current_path(organization_path(organization))
  end
end
