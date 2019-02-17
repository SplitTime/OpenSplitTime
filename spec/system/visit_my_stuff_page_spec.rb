# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the My Stuff page' do
  let(:steward) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:organization_1) { organizations(:hardrock) }
  let(:organization_2) { organizations(:rattlesnake_ramble) }

  before do
    organization_1.stewards << steward
    organization_2.stewards << admin
  end

  scenario 'The user is a non-admin user that is a steward of an organization' do
    login_as steward, scope: :user
    visit my_stuff_user_path(steward)

    verify_org_links_present(organization_1)
  end

  scenario 'The user is a non-admin user that attempts to reach the my_stuff page of another user' do
    login_as steward, scope: :user
    visit my_stuff_user_path(admin)

    expect(page).not_to have_content('My Events')
    expect(page).not_to have_content('My Organizations')
  end

  scenario 'The user is an admin user signing into his own page' do
    login_as admin, scope: :user
    visit my_stuff_user_path(admin)

    pp page.text

    verify_org_links_present(organization_2)
  end

  scenario 'The user is an admin user signing into another user page' do
    login_as admin, scope: :user
    visit my_stuff_user_path(steward)

    verify_org_links_present(organization_1)
  end

  def verify_org_links_present(organization)
    expect(page).to have_content('My Events')
    expect(page).to have_content('My Organizations')
    expect(page).to have_link(organization.name, href: organization_path(organization))
    organization.event_groups.each do |event_group|
      expect(page).to have_link(event_group.name, href: event_group_path(event_group))
    end
  end
end
