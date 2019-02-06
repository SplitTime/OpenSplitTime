# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the event_groups index' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:concealed_event_group) { event_groups(:rufa_2017) }
  let(:concealed_event_1) { concealed_event_group.events.first }
  let(:concealed_event_2) { concealed_event_group.events.second }
  let(:visible_event_group) { event_groups(:sum) }
  let(:visible_event_1) { visible_event_group.events.first }
  let(:visible_event_2) { visible_event_group.events.second }
  let(:organization) { concealed_event_group.organization }

  before { concealed_event_group.update(concealed: true) }

  scenario 'The user is a visitor' do
    visit event_groups_path

    verify_public_links_present
    verify_concealed_links_absent
  end

  scenario 'The user is a non-admin user that did not create the concealed event group' do
    login_as user, scope: :user
    visit event_groups_path

    verify_public_links_present
    verify_concealed_links_absent
  end

  scenario 'The user is a non-admin user that created the concealed event group' do
    login_as owner, scope: :user
    visit event_groups_path

    verify_public_links_present
    verify_concealed_links_present
  end

  scenario 'The user is a non-admin user that is a steward of the organization that owns the concealed event group' do
    login_as steward, scope: :user
    visit event_groups_path

    verify_public_links_present
    verify_concealed_links_present
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit event_groups_path

    verify_public_links_present
    verify_concealed_links_present
  end

  def verify_public_links_present
    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.guaranteed_short_name)
    expect(page).to have_content(visible_event_2.guaranteed_short_name)
  end

  def verify_concealed_links_absent
    expect(page).not_to have_content(concealed_event_group.name)
    expect(page).not_to have_content(concealed_event_1.guaranteed_short_name)
    expect(page).not_to have_content(concealed_event_2.guaranteed_short_name)
  end

  def verify_concealed_links_present
    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.guaranteed_short_name)
    expect(page).to have_content(concealed_event_2.guaranteed_short_name)
  end
end
