# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create an event group" do
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
  let(:new_event_group_name) { "Test Event Group" }
  let(:new_event_group_time_zone) { "Pacific Time (US & Canada)" }
  let(:updated_event_group_name) { "Updated Test Event Group" }
  let(:updated_event_group_time_zone) { "Eastern Time (US & Canada)" }

  scenario "The user is a visitor" do
    verify_unable_to_create_event_group
  end

  scenario "The user is a steward" do
    login_as steward, scope: :user
    verify_unable_to_create_event_group
  end

  scenario "The user owns the organization" do
    login_as owner, scope: :user
    create_and_verify_event_group
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user
    create_and_verify_event_group
  end

  private

  def verify_unable_to_create_event_group
    visit organization_path(organization)
    expect(page).not_to have_link "add-event-group"
  end

  def create_and_verify_event_group
    visit organization_path(organization)
    expect(page).to have_link "add-event-group"
    click_link "add-event-group"

    expect(page).to have_current_path(new_organization_event_group_path(organization))
    expect(page).to have_content("Your Event Group")
    expect(page).to have_button("Continue")

    click_button "Continue"
    expect(page).to have_content(:all, "Name can't be blank")

    fill_in "event_group_name", with: new_event_group_name
    select new_event_group_time_zone, from: "event_group_home_time_zone"

    expect { click_button "Continue" }.to change { EventGroup.count }.by(1)
    new_event_group = EventGroup.last
    expect(new_event_group.name).to eq(new_event_group_name)
    expect(new_event_group.home_time_zone).to eq(new_event_group_time_zone)
    expect(page).to have_current_path(setup_event_group_path(new_event_group))

    click_button("Group Actions")
    click_link("Edit/Delete Group")
    expect(page).to have_current_path(edit_organization_event_group_path(organization, new_event_group))

    expect(page).to have_content(new_event_group.name)
    expect(page).to have_button("Continue")

    fill_in "event_group_name", with: updated_event_group_name
    select updated_event_group_time_zone, from: "event_group_home_time_zone"

    expect { click_button "Continue" }.not_to change { EventGroup.count }
    updated_event_group = EventGroup.last
    expect(updated_event_group.name).to eq(updated_event_group_name)
    expect(updated_event_group.home_time_zone).to eq(updated_event_group_time_zone)
  end
end
