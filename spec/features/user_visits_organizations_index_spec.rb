require 'rails_helper'

feature 'User visits organizations index' do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:visible_organization) { create(:organization, concealed: false) }
  let!(:concealed_organization) { create(:organization, concealed: true, created_by: owner.id) }

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

  scenario 'The user is an admin user' do
    login_as create(:admin), scope: :user
    visit organizations_path

    expect(page).to have_content('Organizations')
    expect(page).to have_content(visible_organization.name)
    expect(page).to have_content(concealed_organization.name)
  end
end
