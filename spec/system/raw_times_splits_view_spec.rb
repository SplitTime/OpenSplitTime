# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the raw times splits page', type: :system do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }

  scenario 'A steward views the raw times splits page' do
    login_as steward, scope: :user

    visit split_raw_times_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'An owner views the raw times splits page' do
    login_as owner, scope: :user

    visit split_raw_times_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'An admin views the raw times splits page' do
    login_as admin, scope: :user

    visit split_raw_times_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'A user changes the view using the split dropdowns' do
    login_as steward, scope: :user

    visit split_raw_times_event_group_path(event_group)
    expect(page).to have_content(event_group.name)

    expect(find('#bib_114')).to have_content('10:00:00')
    expect(find('#bib_777')).to have_content('07:00:00')

    click_link 'Molas Pass (Aid1)'
    page.find_button('Molas Pass (Aid1)')

    expect(find('#bib_130')).to have_content('12:34:00')
    expect(find('#bib_999')).to have_content('08:30:00')
  end
end
