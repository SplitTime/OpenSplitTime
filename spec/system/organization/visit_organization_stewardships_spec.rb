require "rails_helper"

RSpec.describe "Visit an organization stewardships page" do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:hardrock) }

  scenario "The user is a visitor" do
    visit_page

    expect(page).to have_content("You need to sign in or sign up before continuing.")
  end

  scenario "The user is not the owner and not a steward" do
    login_as user, scope: :user
    visit_page

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Access denied")
  end

  scenario "The user owns the organization" do
    login_as owner, scope: :user
    visit_page

    verify_content_present
  end

  scenario "The user is a steward of the organization" do
    login_as steward, scope: :user
    visit_page

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Access denied")
  end

  scenario "The user is an admin user" do
    login_as admin, scope: :user
    visit_page

    verify_content_present
  end

  def visit_page
    visit organization_stewardships_path(organization)
  end

  def verify_content_present
    expect(page).to have_content(organization.name)
    within("#owner_card") do
      expect(page).to have_content(owner.full_name)
      expect(page).to have_content(owner.email)
    end

    within("#stewards_card") do
      expect(page).to have_content(steward.full_name)
      expect(page).to have_content(steward.email)
    end
  end
end
