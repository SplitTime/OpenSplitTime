# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manage stewardships from the organization stewardships page" do
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }

  before { organization.update(created_by: owner.id) }

  let(:organization) { organizations(:hardrock) }

  scenario "The user creates a stewardship" do
    login_as owner, scope: :user
    visit_page

    within("#stewards_card") do
      expect(page).to have_content("No stewards have been added to this organization")

      fill_in "email", with: steward.email
      click_button "Add steward"

      expect(page).to have_content(steward.full_name)
      expect(page).to have_content(steward.email)
    end
  end

  scenario "The user changes stewardship levels" do
    organization.stewards << steward

    login_as owner, scope: :user
    visit_page

    expect do
      within("#stewards_card") do
        select("Lottery Manager", from: "stewardship_level")
        click_button "Confirm"
        expect(page).to have_current_path(organization_stewardships_path(organization))
      end
    end.to change { steward.stewardships.first.level }.from("volunteer").to("lottery_manager")

    expect do
      within("#stewards_card") do
        select("Volunteer", from: "stewardship_level")
        click_button "Confirm"
        expect(page).to have_current_path(organization_stewardships_path(organization))
      end
    end.to change { steward.stewardships.first.level }.from("lottery_manager").to("volunteer")
  end

  scenario "The user deletes a stewardship" do
    organization.stewards << steward

    login_as owner, scope: :user
    visit_page

    within("#stewards_card") do
      expect(page).to have_content(steward.full_name)
      expect(page).to have_content(steward.email)

      click_link "Remove"

      expect(page).to have_content("No stewards have been added to this organization")
    end
  end

  def visit_page
    visit organization_stewardships_path(organization)
  end
end
