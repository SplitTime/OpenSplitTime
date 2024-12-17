# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visit the My Stuff page", js: true do
  let(:steward) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:organization_1) { organizations(:hardrock) }
  let(:organization_2) { organizations(:rattlesnake_ramble) }

  before do
    organization_1.stewards << steward
    organization_2.stewards << admin
  end

  scenario "The user is a non-admin user that is a steward of an organization" do
    login_as steward, scope: :user
    visit_my_stuff_path

    verify_org_links_present(organization_1)
  end

  scenario "The user is an admin user" do
    login_as admin, scope: :user
    visit_my_stuff_path

    verify_org_links_present(organization_2)
  end

  def visit_my_stuff_path
    visit my_stuff_path
  end

  def verify_org_links_present(organization)
    expect(page).to have_content("My Events")
    expect(page).to have_content("My Organizations")
    verify_link_present(organization)
    organization.event_groups.each(&method(:verify_link_present))
  end
end
