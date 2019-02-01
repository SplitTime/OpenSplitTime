# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the organizations index' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    concealed_organization_1.update(created_by: owner.id)
    concealed_organization_2.stewards << steward
  end

  let(:concealed_organization_1) { organizations(:running_up_for_air) }
  let(:concealed_organization_2) { organizations(:hardrock) }
  let(:concealed_organizations) { [concealed_organization_1, concealed_organization_2] }
  let(:visible_organizations) { organizations - concealed_organizations }

  before do
    concealed_organizations.each { |org| org.update(concealed: true) }
  end

  scenario 'The user is a visitor' do
    visit organizations_path

    verify_public_links_present
    verify_concealed_links_absent
  end

  scenario 'The user is a non-admin user is neither owner nor steward of any concealed organization' do
    login_as user, scope: :user
    visit organizations_path

    verify_public_links_present
    verify_concealed_links_absent
  end

  scenario 'The user is a non-admin user that created a concealed organization' do
    login_as owner, scope: :user
    visit organizations_path

    verify_public_links_present
    verify_link_present(concealed_organization_1)
    verify_content_absent(concealed_organization_2)
  end

  scenario 'The user is a non-admin user that is a steward of a concealed organization' do
    login_as steward, scope: :user
    visit organizations_path

    verify_public_links_present
    verify_link_present(concealed_organization_2)
    verify_content_absent(concealed_organization_1)
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit organizations_path

    verify_public_links_present
    concealed_organizations.each { |org| expect(page).to have_link(org.name, href: organization_path(org)) }
  end

  def verify_public_links_present
    expect(page).to have_content('Organizations')
    visible_organizations.each { |org| expect(page).to have_link(org.name, href: organization_path(org)) }
  end

  def verify_concealed_links_absent
    concealed_organizations.each { |org| expect(page).not_to have_content(org.name) }
  end
end
