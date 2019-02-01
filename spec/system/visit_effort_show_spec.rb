# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an effort show page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards.delete_all
    organization.stewards << steward
  end

  let(:event) { events(:hardrock_2014) }
  let(:organization) { event.organization }

  let(:completed_effort) { efforts(:hardrock_2014_finished_first) }
  let(:in_progress_effort) { efforts(:hardrock_2014_progress_sherman) }
  let(:unstarted_effort) { efforts(:hardrock_2014_not_started) }

  context 'When the effort is finished' do
    let(:effort) { completed_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      verify_page_header
      expect(page).not_to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).not_to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end
  end

  context 'When the effort is in progress' do
    let(:effort) { in_progress_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      verify_page_header
      expect(page).not_to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).not_to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end
  end

  context 'When the effort is not started' do
    let(:effort) { unstarted_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      verify_page_header
      expect(page).not_to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).not_to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)
      verify_page_header
      expect(page).to have_link('Edit effort', href: edit_effort_path(effort))
    end
  end


  def verify_page_header
    expect(page).to have_content(effort.full_name)
    expect(page).to have_content('Split times')

    if effort == in_progress_effort
      expect(page).to have_link('Projections', href: projections_effort_path(effort))
    else
      expect(page).not_to have_link('Projections', href: projections_effort_path(effort))
    end

    if effort == unstarted_effort
      expect(page).not_to have_link('Analyze times', href: analyze_effort_path(effort))
      expect(page).not_to have_link('Places + peers', href: place_effort_path(effort))
    else
      expect(page).to have_link('Analyze times', href: analyze_effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end
  end

  def verify_split_names
    event.splits.each { |split| expect(page).to have_content(split.base_name) }
  end
end
