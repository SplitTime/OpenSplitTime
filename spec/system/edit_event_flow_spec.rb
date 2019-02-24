# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the edit event page and make changes', type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event) { events(:hardrock_2014) }
  let(:organization) { event.organization }

  scenario 'The user is a visitor' do
    visit edit_event_path(event)

    expect(page).to have_current_path(root_path)
    expect(page.find('.alert')).to have_content('You need to sign in or sign up before continuing')
  end

  scenario 'The user is a user that is not authorized to edit the event' do
    login_as user, scope: :user

    visit edit_event_path(event)

    expect(page).to have_current_path(root_path)
    expect(page.find('.alert')).to have_content('Access denied')
  end

  scenario 'The user is a steward of the organization' do
    login_as steward, scope: :user

    visit edit_event_path(event)
    verify_visit_and_update

    visit edit_event_path(event)
    expect(page).not_to have_link('Delete this event')
  end

  scenario 'The user is the owner of the organization' do
    login_as owner, scope: :user

    visit edit_event_path(event)
    verify_visit_and_update

    visit edit_event_path(event)
    verify_confirm_and_delete
  end

  scenario 'The user is an admin' do
    login_as admin, scope: :user

    visit edit_event_path(event)
    verify_visit_and_update

    visit edit_event_path(event)
    verify_confirm_and_delete
  end

  def verify_visit_and_update
    expect(page).to have_current_path(edit_event_path(event))
    expect(event.short_name).to eq(nil)

    fill_in 'Short name', with: 'Silverton'
    click_button 'Update Event'

    event.reload
    expect(event.short_name).to eq('Silverton')
  end

  def verify_confirm_and_delete
    click_link 'Delete this event'
    modal = page.find('aside')
    expect(modal).to have_content('Are you absolutely sure?')
    expect(modal).to have_link('Permanently Delete', class: 'disabled')

    fill_in 'confirm', with: event.name.upcase
    expect(modal).not_to have_link('Permanently Delete', class: 'disabled')
    expect(modal).to have_link('Permanently Delete')

    expect { click_link 'Permanently Delete' }.to change { Event.count }.by(-1)
    expect(page).to have_current_path(event_groups_path)
  end
end
