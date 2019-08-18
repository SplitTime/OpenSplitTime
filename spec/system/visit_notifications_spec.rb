# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an event group notifications page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:rufa_2017) }
  let(:organization) { event_group.organization }

  scenario 'The user is an admin' do
    login_as admin, scope: :user
    visit notifications_event_group_path(event_group)
    verify_links_present
  end

  scenario 'The user is the owner of the organization' do
    login_as owner, scope: :user
    visit notifications_event_group_path(event_group)
    verify_links_present
  end

  scenario 'The user is a steward of the event_group' do
    login_as steward, scope: :user
    visit notifications_event_group_path(event_group)
    verify_links_present
  end

  def verify_links_present
    verify_content_present(event_group)
  end
end
