# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an effort show page' do
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

  let(:completed_effort) { efforts(:hardrock_2014_finished_first) }
  let(:in_progress_effort) { efforts(:hardrock_2014_progress_sherman) }
  let(:unstarted_effort) { efforts(:hardrock_2014_not_started) }

  context 'When the effort is finished' do
    let(:effort) { completed_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is a user who created the effort' do
      login_as owner, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
    end
  end

  context 'When the effort is in progress' do
    let(:effort) { in_progress_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is a user who created the effort' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
    end
  end

  context 'When the effort is not started' do
    let(:effort) { unstarted_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is a user who did not create the associated event and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is a user who created the effort' do
      login_as owner, scope: :user
      visit effort_path(effort)

      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)

      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)

      verify_page_content
      verify_admin_links_present
    end
  end


  def verify_page_content
    expect(page).to have_content(effort.full_name)
    expect(page).to have_content('Split times')

    if effort == in_progress_effort
      expect(page).to have_link('Projections', href: projections_effort_path(effort))
    else
      expect(page).not_to have_content('Projections')
    end

    if effort == unstarted_effort
      expect(page).not_to have_content('Analyze times')
      expect(page).not_to have_content('Places + peers')
    else
      expect(page).to have_link('Analyze times', href: analyze_effort_path(effort))
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end

    event.splits.each { |split| expect(page).to have_content(split.base_name) }
  end

  def verify_admin_links_absent
    expect(page).not_to have_content('Edit Entrant')
  end

  def verify_admin_links_present
    expect(page).to have_link('Edit Entrant', href: edit_effort_path(effort))
  end
end
