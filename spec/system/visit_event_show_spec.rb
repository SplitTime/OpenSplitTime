# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit a populated event show page and try various features' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event) { events(:sum_55k) }
  let(:course) { event.course }
  let(:event_group) { event.event_group }
  let(:organization) { event.organization }
  let(:effort_1) { event.efforts.sample }
  let(:other_efforts) { event.efforts.where.not(id: effort_1.id) }

  scenario 'The user is a visitor' do
    visit event_path(event)

    verify_public_links_present
    verify_admin_links_absent
  end

  scenario 'The user is a user who did not create the event and is not a steward' do
    login_as user, scope: :user
    visit event_path(event)

    verify_public_links_present
    verify_admin_links_absent
  end

  scenario 'The user is a user who created the event' do
    login_as owner, scope: :user
    visit event_path(event)

    verify_public_links_present
    verify_admin_links_present
  end

  scenario 'The user is a steward of the organization related to the event' do
    login_as steward, scope: :user
    visit event_path(event)

    verify_public_links_present
    verify_admin_links_present
  end

  scenario 'The user is an admin' do
    login_as admin, scope: :user
    visit event_path(event)

    verify_public_links_present
    verify_admin_links_present
  end

  scenario 'The user searches for a name' do
    visit event_path(event)
    verify_public_links_present

    fill_in 'Bib #, First name, Last name, State, or Country', with: effort_1.full_name
    click_button 'Find someone'

    expect(page).to have_content(effort_1.full_name)
    other_efforts.each { |effort| expect(page).not_to have_content(effort.full_name) }

    fill_in 'Bib #, First name, Last name, State, or Country', with: effort_1.bib_number
    click_button 'Find someone'

    expect(page).to have_content(effort_1.full_name)
    other_efforts.each { |effort| expect(page).not_to have_content(effort.full_name) }
  end

  def verify_public_links_present
    expect(page).to have_link(event_group.name, href: event_group_path(event_group)) ||
                        have_link(event.name, href: event_group_path(event_group))
    expect(page).to have_link('Spread', href: spread_event_path(event))
    expect(page).to have_link('Plan my effort', href: plan_effort_course_path(course), visible: :all)
    expect(page).to have_link('All-time best', href: best_efforts_course_path(course))
    event.efforts.each { |effort| expect(page).to have_link(effort.full_name, href: effort_path(effort)) }
  end

  def verify_admin_links_present
    expect(page).to have_link('Staging', href: "#{event_staging_app_path(event)}#/entrants")
    expect(page).to have_link('Roster', href: roster_event_group_path(event_group))
    expect(page).to have_link('Settings', href: event_group_path(event_group, force_settings: true))
  end

  def verify_admin_links_absent
    expect(page).not_to have_link('Staging')
    expect(page).not_to have_link('Roster')
    expect(page).not_to have_link('Settings')
  end
end
