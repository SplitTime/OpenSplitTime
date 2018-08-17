# frozen_string_literal: true

require 'rails_helper'
include FeatureMacros

RSpec.describe 'visit a an effort analyze page' do
  before(:context) do
    create_hardrock_event
  end

  after(:context) do
    clean_up_database
  end

  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:steward) { create(:user) }
  let(:admin) { create(:admin) }

  let(:event) { Event.first }
  let(:course) { Course.first }

  let(:enriched_efforts) { Effort.ranked_with_status }
  let(:completed_effort) { enriched_efforts.find(&:finished) }
  let(:partial_effort) { enriched_efforts.select(&:started).reject(&:finished).first }
  let(:unstarted_effort) { enriched_efforts.reject(&:started).first }

  context 'When the effort is finished' do
    let(:effort) { completed_effort }
    before { expect(effort.split_times.size).to eq(30) }

    scenario 'The user is a visitor' do
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is a steward of the organization related to the event' do
      event = Event.first
      organization = event.event_group.organization
      organization.stewards << steward

      login_as steward, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end
  end

  context 'when the effort is partially finished' do
    let(:effort) { partial_effort }
    before { expect(effort.split_times.size).to eq(15) }

    scenario 'The user is a visitor' do
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is a steward of the organization related to the event' do
      event = Event.first
      organization = event.event_group.organization
      organization.stewards << steward

      login_as steward, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_link('Split times', href: effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end
  end

  context 'when the effort is not started' do
    let(:effort) { unstarted_effort }
    before { expect(effort.split_times.size).to eq(0) }

    scenario 'The user is a visitor' do
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_text('Cannot analyze an unstarted effort')
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_text('Cannot analyze an unstarted effort')
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_text('Cannot analyze an unstarted effort')
    end

    scenario 'The user is a steward of the organization related to the event' do
      event = Event.first
      organization = event.event_group.organization
      organization.stewards << steward

      login_as steward, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_text('Cannot analyze an unstarted effort')
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit analyze_effort_path(effort)

      expect(page).to have_content(effort.full_name)
      expect(page).to have_text('Cannot analyze an unstarted effort')
    end
  end
end
