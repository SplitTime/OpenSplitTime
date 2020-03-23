# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit an event group settings page and try various features' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:dirty_30_running) }
  let(:event_group) { event_groups(:sum) }
  let(:event_1) { event_group.events.first }
  let(:event_2) { event_group.events.second }

  let(:outside_event_group) { event_groups(:rufa_2017) }
  let(:outside_event_1) { outside_event_group.events.first }
  let(:outside_event_2) { outside_event_group.events.second }


  context 'The event group is visible' do
    scenario 'The user is a visitor' do
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_absent
      verify_admin_links_absent
      verify_outside_content_absent
    end

    scenario 'The user is not the owner and not a steward' do
      login_as user, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_absent
      verify_admin_links_absent
      verify_outside_content_absent
    end

    scenario 'The user owns the organization' do
      login_as owner, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_present
      verify_outside_content_absent
    end

    scenario 'The user is a steward of the organization' do
      login_as steward, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_absent
      verify_outside_content_absent
    end

    scenario 'The user is an admin user' do
      login_as admin, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_present
      verify_outside_content_absent
    end
  end

  context 'The event group is concealed' do
    before { event_group.update(concealed: true) }

    scenario 'The user is a visitor' do
      verify_record_not_found
    end

    scenario 'The user is not the owner and not a steward' do
      login_as user, scope: :user
      verify_record_not_found
    end

    scenario 'The user owns the organization' do
      login_as owner, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_present
      verify_outside_content_absent
    end

    scenario 'The user is a steward of the organization' do
      login_as steward, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_absent
      verify_outside_content_absent
    end

    scenario 'The user is an admin user' do
      login_as admin, scope: :user
      visit event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_present
      verify_outside_content_absent
    end

    # Ensure policy scoping is working as expected, i.e., ignoring created_by
    # and looking only at the organization owner.
    context 'The event group has an event that was created by an admin' do
      before { event_2.update(created_by: admin.id) }

      scenario 'The user owns the organization' do
        login_as owner, scope: :user
        visit event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_present
        verify_outside_content_absent
      end

      scenario 'The user is a steward of the organization' do
        login_as steward, scope: :user
        visit event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_absent
        verify_outside_content_absent
      end

      scenario 'The user is an admin user' do
        login_as admin, scope: :user
        visit event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_present
        verify_outside_content_absent
      end
    end
  end

  scenario 'The user is a visitor that clicks an event link' do
    visit event_group_path(event_group)
    click_link event_1.name

    expect(page).to have_content(event_1.name)
    expect(page).to have_content('Full results')
  end

  def verify_public_links_present
    expect(page).to have_content(organization.name)

    verify_link_present(event_1)
    verify_link_present(event_2)
  end

  def verify_outside_content_absent
    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.guaranteed_short_name)
    expect(page).not_to have_content(outside_event_2.guaranteed_short_name)
  end

  def verify_steward_links_absent
    expect(page).not_to have_content('Edit/Delete Event')
  end

  def verify_steward_links_present
    expect(page).to have_link('Edit/Delete Event', href: edit_event_path(event_1))
    expect(page).to have_link('Edit/Delete Event', href: edit_event_path(event_2))
  end

  def verify_admin_links_absent
    expect(page).not_to have_content('Make private')
    expect(page).not_to have_content('Make public')
    expect(page).not_to have_content('Disable live')
    expect(page).not_to have_content('Enable live')
    expect(page).not_to have_content('Group Actions')
  end

  def verify_admin_links_present
    if event_group.concealed?
      expect(page).to have_link('Make public', href: event_group_path(event_group, event_group: {concealed: false}))
    else
      expect(page).to have_link('Make private', href: event_group_path(event_group, event_group: {concealed: true}))
    end

    if event_group.available_live?
      expect(page).to have_link('Disable live', href: event_group_path(event_group, event_group: {available_live: false}))
    else
      expect(page).to have_link('Enable live', href: event_group_path(event_group, event_group: {available_live: true}))
    end

    expect(page).to have_content('Group Actions')
  end

  def verify_record_not_found
    expect { visit event_group_path(event_group) }.to raise_error ::ActiveRecord::RecordNotFound
  end
end
