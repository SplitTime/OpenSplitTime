require "rails_helper"

RSpec.describe "visit connections index page" do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:hardrock) }
  let(:event_group) { event_groups(:hardrock_2015) }

  context "The event group is visible" do
    scenario "The user is a visitor" do
      visit_page

      expect(page).to have_current_path(root_path)
      verify_alert("You need to sign in or sign up before continuing")
    end

    scenario "The user is not the owner and not a steward" do
      login_as user, scope: :user
      visit_page

      expect(page).to have_current_path(root_path)
      verify_alert("Access denied")
    end

    scenario "The user owns the organization" do
      login_as owner, scope: :user
      visit_page

      verify_content_present
      verify_working_link
    end

    scenario "The user is a steward of the organization" do
      login_as steward, scope: :user
      visit_page

      verify_content_present
      verify_working_link
    end

    scenario "The user is an admin" do
      login_as admin, scope: :user
      visit_page

      verify_content_present
      verify_working_link
    end
  end

  def visit_page
    visit event_group_connections_path(event_group)
  end

  def verify_content_present
    expect(page).to have_content(organization.name)
    expect(page).to have_button("Select a service to connect")

    # Open the dropdown menu
    click_button("Select a service to connect")

    Connectors::Service.all.each do |service|
      expect(page).to have_content(service.name)
    end

    # Close the dropdown menu
    click_button("Select a service to connect")
  end

  def verify_working_link
    service = Connectors::Service.all.first
    click_button("Select a service to connect")
    click_link(service.name)

    expect(page).to have_current_path(event_group_connect_service_path(event_group, service))
  end
end
