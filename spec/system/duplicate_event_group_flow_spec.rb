# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'create a duplicate event group using the duplicate event group page', type: :system, js: true do
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
  let(:new_date) { '2019-02-28' }

  scenario 'The user is a visitor' do
    visit duplicate_event_group_path(event_group)

    expect(page).to have_current_path(root_path)
    verify_alert('You need to sign in or sign up before continuing')
  end

  scenario 'The user is a user that is not authorized to edit the event group' do
    login_as user, scope: :user

    visit duplicate_event_group_path(event_group)

    expect(page).to have_current_path(root_path)
    verify_alert('Access denied')
  end

  context 'when event start times have the same date as UTC date' do
    scenario 'The user is a steward of the organization' do
      login_as steward, scope: :user

      visit duplicate_event_group_path(event_group)
      verify_visit_and_duplication
    end

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user

      visit duplicate_event_group_path(event_group)
      verify_visit_and_duplication
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user

      visit duplicate_event_group_path(event_group)
      verify_visit_and_duplication
    end

    scenario 'The name has been taken' do
      login_as admin, scope: :user

      visit duplicate_event_group_path(event_group)
      fill_in 'event_group_name', with: 'SUM'
      fill_in 'event_group_duplicate_event_date', with: new_date
      click_button 'Duplicate Event Group'
      expect(page).to have_current_path(duplicate_event_group_path(event_group))
      verify_alert('Name has already been taken')
    end

    scenario 'The name is blank' do
      login_as admin, scope: :user

      visit duplicate_event_group_path(event_group)
      fill_in 'event_group_name', with: ''
      fill_in 'event_group_duplicate_event_date', with: new_date
      click_button 'Duplicate Event Group'
      expect(page).to have_current_path(duplicate_event_group_path(event_group))
      verify_alert(/Name can't be blank/)
    end

    scenario 'The date is blank' do
      login_as admin, scope: :user

      visit duplicate_event_group_path(event_group)
      verify_invalid_date('')
    end

    scenario 'The date is invalid' do
      login_as admin, scope: :user

      visit duplicate_event_group_path(event_group)
      verify_invalid_date('hello')
    end
  end

  context 'when event start times have a different local date as UTC date' do
    let(:event_group) { event_groups(:dirty_30) }

    scenario 'The user is authorized to edit the organization' do
      login_as steward, scope: :user

      visit duplicate_event_group_path(event_group)
      verify_visit_and_duplication
    end
  end

  def verify_visit_and_duplication
    expect(page).to have_current_path(duplicate_event_group_path(event_group))

    fill_in 'event_group_name', with: 'SUM New'
    fill_in 'event_group_duplicate_event_date', with: new_date
    click_button 'Duplicate Event Group'
    page.find('h1', text: 'SUM New')
    new_event_group = EventGroup.last

    expect(page).to have_current_path(event_group_path(new_event_group, force_settings: true))

    expect(new_event_group.name).to eq('SUM New')
    expect(new_event_group.events.map(&:short_name)).to match_array(event_group.events.map(&:short_name))

    new_events = Event.last(2)
    new_events.each do |event|
      verify_link_present(event)
      expect(event.start_time_local.to_date).to eq(new_date.to_date)
    end
  end

  def verify_invalid_date(string)
    fill_in 'event_group_name', with: 'SUM New'
    fill_in 'event_group_duplicate_event_date', with: string
    click_button 'Duplicate Event Group'
    expect(page).to have_current_path(duplicate_event_group_path(event_group))
    verify_alert(/Date is invalid/)
  end
end
