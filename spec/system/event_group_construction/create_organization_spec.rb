require "rails_helper"

RSpec.describe "Create a new organization" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  scenario "The user is a visitor" do
    visit_page

    expect(page).to have_current_path(root_path)
    expect(page).to have_text("You need to sign in or sign up before continuing")
  end

  scenario "The user is a non-admin user" do
    login_as user, scope: :user
    visit_page

    verify_organization_creation
  end

  scenario "The user is an admin user" do
    login_as admin, scope: :user
    visit_page

    verify_organization_creation
  end

  def visit_page
    visit new_organization_path
  end

  def verify_organization_creation
    expect(page).to have_content("New Organization")
    fill_in "Name", with: "My Organization"
    fill_in "Description", with: "This is my organization"

    expect do
      click_button "Continue"
    end.to change { Organization.count }.by(1)

    new_organization = Organization.last
    expect(new_organization.name).to eq("My Organization")
    expect(page).to have_current_path(new_organization_event_group_path(new_organization))
  end
end
