# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the duplicate event group page', type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:event_group) { event_groups(:sum) }

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
end
