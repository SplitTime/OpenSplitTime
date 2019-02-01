# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the event_groups index' do
  let(:user) { users(:third_user) }
  let(:owner) { create(:user) }
  let(:steward) { create(:user) }
  let(:admin) { users(:admin_user) }
  let!(:visible_event_1) { create(:event, event_group: visible_event_group) }
  let!(:visible_event_2) { create(:event, event_group: visible_event_group) }
  let!(:concealed_event_1) { create(:event, event_group: concealed_event_group) }
  let!(:concealed_event_2) { create(:event, event_group: concealed_event_group) }
  let(:visible_event_group) { create(:event_group, concealed: false) }
  let(:concealed_event_group) { create(:event_group, concealed: true, organization: organization, created_by: owner.id) }
  let(:organization) { create(:organization) }
  before do
    organization.stewards << steward
  end

  scenario 'The user is a visitor' do
    visit event_groups_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
    expect(page).not_to have_content(concealed_event_1.name)
    expect(page).not_to have_content(concealed_event_2.name)
  end

  scenario 'The user is a non-admin user that did not create the concealed event group' do
    login_as user, scope: :user
    visit event_groups_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
    expect(page).not_to have_content(concealed_event_1.name)
    expect(page).not_to have_content(concealed_event_2.name)
  end

  scenario 'The user is a non-admin user that created the concealed event group' do
    login_as owner, scope: :user
    visit event_groups_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)
    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.name)
    expect(page).to have_content(concealed_event_2.name)
  end

  scenario 'The user is a non-admin user that is a steward of the organization that owns the concealed event group' do
    login_as steward, scope: :user
    visit event_groups_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)
    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.name)
    expect(page).to have_content(concealed_event_2.name)
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit event_groups_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)
    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.name)
    expect(page).to have_content(concealed_event_2.name)
  end
end
