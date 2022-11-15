# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit the edit event page and make changes", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event) { events(:hardrock_2014) }
  let(:event_group) { event.event_group }
  let(:organization) { event.organization }

  scenario "The user is a visitor" do
    visit edit_event_group_event_path(event_group, event)

    expect(page).to have_current_path(root_path)
    verify_alert("You need to sign in or sign up before continuing")
  end

  scenario "The user is a user that is not authorized to edit the event" do
    login_as user, scope: :user

    visit edit_event_group_event_path(event_group, event)

    expect(page).to have_current_path(root_path)
    verify_alert("Access denied")
  end

  scenario "The user is a steward of the organization" do
    login_as steward, scope: :user

    visit edit_event_group_event_path(event_group, event)
    verify_visit_and_update

    expect(page).not_to have_link("Delete this event")
  end

  scenario "The user is the owner of the organization" do
    login_as owner, scope: :user

    visit edit_event_group_event_path(event_group, event)
    verify_visit_and_update

    visit edit_event_group_event_path(event_group, event)
    verify_confirm_and_delete
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user

    visit edit_event_group_event_path(event_group, event)
    verify_visit_and_update

    visit edit_event_group_event_path(event_group, event)
    verify_confirm_and_delete
  end

  def verify_visit_and_update
    expect(page).to have_current_path(edit_event_group_event_path(event_group, event))
    expect(event.short_name).to eq(nil)

    fill_in "Short name", with: "Silverton"
    click_button "Save changes"

    expect(page).to have_current_path(setup_event_group_path(event_group))

    event.reload
    expect(event.short_name).to eq("Silverton")
  end

  def verify_confirm_and_delete
    click_link "Delete this event"
    modal = page.find("aside")
    expect(modal).to have_content("Are you absolutely sure?")
    expect(modal).to have_link("Permanently Delete", class: "disabled")

    fill_in "confirm", with: event.name.upcase
    expect(modal).not_to have_link("Permanently Delete", class: "disabled")
    expect(modal).to have_link("Permanently Delete")

    expect do
      click_link "Permanently Delete"
      expect(page).to have_current_path(setup_event_group_path(event_group))
    end.to change { Event.count }.by(-1)
  end
end
