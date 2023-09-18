# frozen_string_literal: true

require "rails_helper"

RSpec.describe "create and edit splits from the events setup_course view", js: true do
  let(:owner) { users(:third_user) }

  before { organization.update(created_by: owner.id) }

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }
  let(:event) { events(:sum_100k) }
  let(:course) { event.course }
  let(:existing_split) { splits(:sum_100k_course_molas_pass_aid1) }

  scenario "Create a new split" do
    login_as owner, scope: :user
    visit_page

    expect do
      click_link "Add", href: new_event_group_event_split_path(event_group, event)
      expect(page).to have_content("New Split")

      fill_in "split_base_name", with: "Another Aid Station"
      fill_in "split_distance_in_preferred_units", with: "25"

      # Wait for things to settle
      sleep 0.3

      click_button "Create Split"

      # Wait for the modal to close
      expect(page).not_to have_content("New Split")

      # Wait for the update to complete
      expect(page).not_to have_css(".bg-highlight")
    end.to change { event.reload.splits.size }.by(1)

    expect(page).to have_content("Another Aid Station")
  end

  scenario "Update an existing split" do
    login_as owner, scope: :user
    visit_page

    expect do
      click_link href: edit_event_group_event_split_path(event_group, event, existing_split)
      expect(page).to have_content("Update Molas Pass (Aid1)")

      fill_in "split_distance_in_preferred_units", with: "12.5"

      # Wait for things to settle
      sleep 0.3

      click_button "Update Split"

      # Wait for the modal to close
      expect(page).not_to have_content("Update Molas Pass (Aid1)")

      # Wait for the update to complete
      expect(page).not_to have_css(".bg-highlight")
    end.to change { existing_split.reload.distance_from_start }.from(18347).to(20117)

    expect(page).to have_content("12.5")
  end

  def visit_page
    visit setup_course_event_group_event_path(event_group, event)
  end
end
