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

  let(:event) { effort.event }
  let(:event_group) { event.event_group}
  let(:organization) { event_group.organization }

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

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is the owner' do
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

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is the owner' do
      effort.update(created_by: owner.id)

      login_as owner, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
      verify_set_stop
      verify_remove_stop
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
      verify_set_stop
      verify_remove_stop
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_present
      verify_set_stop
      verify_remove_stop
    end
  end

  context 'When the effort is not started' do
    let(:effort) { unstarted_effort }

    scenario 'The user is a visitor' do
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      visit effort_path(effort)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is the owner' do
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

  context 'when the effort is hidden' do
    let(:effort) { completed_effort }
    before { event_group.update(concealed: true) }

    scenario 'The user is a visitor' do
      verify_page_not_found
    end

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      verify_page_not_found
    end

    scenario 'The user is the owner' do
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
    expect(page).not_to have_content('Audit')
  end

  def verify_admin_links_present
    expect(page).to have_link('Edit Entrant', href: edit_effort_path(effort))
    expect(page).to have_link('Audit', href: audit_effort_path(effort))
  end

  def verify_set_stop
    effort.reload
    expect(effort.ordered_split_times.last).not_to be_stopped_here
    click_link 'Set stop'

    expect(page).to have_content 'Remove stop'
    effort.reload
    expect(effort.ordered_split_times.last).to be_stopped_here
  end

  def verify_remove_stop
    effort.reload
    expect(effort.ordered_split_times.last).to be_stopped_here
    click_link 'Remove stop'

    expect(page).to have_content 'Set stop'
    effort.reload
    expect(effort.ordered_split_times.last).not_to be_stopped_here
  end

  def verify_page_not_found
    expect { visit effort_path(effort) }.to raise_error ::ActiveRecord::RecordNotFound
  end
end
