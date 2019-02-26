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
    expect(page.find('.alert')).to have_content('You need to sign in or sign up before continuing')
  end

  scenario 'The user is a user that is not authorized to edit the event group' do
    login_as user, scope: :user

    visit duplicate_event_group_path(event_group)

    expect(page).to have_current_path(root_path)
    expect(page.find('.alert')).to have_content('Access denied')
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
    expect { click_button 'Duplicate Event Group' }.to change { EventGroup.count }.by(1).and change { Event.count }.by(2)
    new_event_group = EventGroup.last
    new_events = Event.last(2)

    expect(page).to have_current_path(event_group_path(new_event_group, force_settings: true))
    new_events.each do |event|
      expect(page).to have_link(event.name, href: event_path(event))
      expect(event.start_time_local.to_date).to eq(new_date.to_date)
    end
  end
end
