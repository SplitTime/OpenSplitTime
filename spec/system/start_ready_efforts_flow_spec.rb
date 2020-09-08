# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'start ready efforts from the event groups roster page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:hardrock_2014) }
  let(:organization) { event_group.organization }
  let(:event_group_efforts) { event_group.efforts.roster_subquery }

  context 'when no efforts are ready to start' do
    before { expect(event_group_efforts.map(&:ready_to_start)).to all eq(false) }

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_disabled
    end

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_disabled
    end

    scenario 'The user is a steward of the event_group' do
      login_as steward, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_disabled
    end
  end

  context 'when an unstarted effort is ready to start' do
    before { efforts(:hardrock_2014_not_started).update(checked_in: true) }

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_enabled
    end

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_enabled
    end

    scenario 'The user is a steward of the event_group' do
      login_as steward, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_enabled
    end
  end

  context 'when an effort in progress without a start time is ready to start' do
    before { efforts(:hardrock_2014_without_start).update(checked_in: true) }

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_enabled
    end

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_enabled
    end

    scenario 'The user is a steward of the event_group' do
      login_as steward, scope: :user
      visit roster_event_group_path(event_group)

      verify_start_button_enabled
    end
  end

  def verify_start_button_disabled
    expect(start_button[:disabled]).to eq 'disabled'
  end

  def verify_start_button_enabled
    expect(start_button[:disabled]).to be_nil
  end

  def start_button
    find('.start-ready-efforts')
  end
end
