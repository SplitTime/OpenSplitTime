# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'create a duplicate event group using the duplicate event group page', type: :system do
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

  context 'when event start times have the same date as UTC date' do
    scenario 'The user is a steward of the organization' do
      login_as steward, scope: :user

      visit new_duplicate_path
      verify_visit_and_duplication
    end

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user

      visit new_duplicate_path
      verify_visit_and_duplication
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user

      visit new_duplicate_path
      verify_visit_and_duplication
    end

    scenario 'The name has been taken' do
      login_as admin, scope: :user

      visit new_duplicate_path
      fill_in_name('SUM')
      fill_in_date(new_date)
      click_button 'Duplicate Event Group'
      verify_did_not_leave_page
    end

    scenario 'The name is blank' do
      login_as admin, scope: :user

      visit new_duplicate_path
      fill_in_name('')
      fill_in_date(new_date)
      click_button 'Duplicate Event Group'
      verify_did_not_leave_page
    end

    scenario 'The date is blank' do
      login_as admin, scope: :user

      visit new_duplicate_path
      verify_invalid_date('')
    end

    scenario 'The date is invalid' do
      login_as admin, scope: :user

      visit new_duplicate_path
      verify_invalid_date('hello')
    end
  end

  context 'when event start times have a different local date as UTC date' do
    let(:event_group) { event_groups(:dirty_30) }

    scenario 'The user is authorized to edit the organization' do
      login_as steward, scope: :user

      visit new_duplicate_path
      verify_visit_and_duplication
    end
  end

  def verify_visit_and_duplication
    expect(page).to have_current_path(new_duplicate_path)

    fill_in_name('SUM New')
    fill_in_date(new_date)
    expect do
      click_button 'Duplicate Event Group'
      page.find('h1', text: 'SUM New')
    end.to change { EventGroup.count }.by(1).and change { Event.count }.by(2)

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
    fill_in_name('SUM New')
    fill_in_date(string)
    click_button 'Duplicate Event Group'
    verify_did_not_leave_page
  end

  def fill_in_name(text)
    fill_in 'duplicate_event_group_new_name', with: text
  end

  def fill_in_date(text)
    fill_in 'duplicate_event_group_new_start_date', with: text
  end

  def new_duplicate_path
    new_duplicate_event_group_path(existing_id: event_group.id)
  end

  def verify_did_not_leave_page
    expect(page).to have_css('h1', text: 'Duplicate Event Group')
  end
end
