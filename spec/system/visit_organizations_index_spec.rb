# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the organizations index' do
  let(:user) { users(:third_user) }
  let(:owner) { create(:user) }
  let(:steward) { create(:user) }
  let(:admin) { users(:admin_user) }
  let!(:visible_organization) { create(:organization, concealed: false) }
  let!(:concealed_organization) { create(:organization, concealed: true, created_by: owner.id) }
  before do
    concealed_organization.stewards << steward
  end

  scenario 'The user is a visitor' do
    visit organizations_path

    expect(page).to have_content('Organizations')
    expect(page).to have_content(visible_organization.name)
    expect(page).not_to have_content(concealed_organization.name)
  end

  scenario 'The user is a non-admin user that did not create the concealed organization' do
    login_as user, scope: :user
    visit organizations_path

    expect(page).to have_content('Organizations')
    expect(page).to have_content(visible_organization.name)
    expect(page).not_to have_content(concealed_organization.name)
  end

  scenario 'The user is a non-admin user that created the concealed organization' do
    login_as owner, scope: :user
    visit organizations_path

    expect(page).to have_content('Organizations')
    expect(page).to have_content(visible_organization.name)
    expect(page).to have_content(concealed_organization.name)
  end

  scenario 'The user is a non-admin user that is a steward of the concealed organization' do
    login_as steward, scope: :user
    visit organizations_path

    expect(page).to have_content('Organizations')
    expect(page).to have_content(visible_organization.name)
    expect(page).to have_content(concealed_organization.name)
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit organizations_path

    expect(page).to have_content('Organizations')
    expect(page).to have_content(visible_organization.name)
    expect(page).to have_content(concealed_organization.name)
  end
end
