# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the follow page' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:hardrock_2015) }

  scenario 'A visitor views the follow page' do
    visit follow_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'A user views the follow page' do
    login_as user, scope: :user

    visit follow_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'An admin views the follow page' do
    login_as admin, scope: :user

    visit follow_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end
end
